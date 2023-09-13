# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class FetchAndSaveWorkMetadata
      include Hyrax::Autopopulation::ParseIdentifier

      attr_accessor :user, :account, :doi_list, :rejected_doi_list

      def initialize(user:, doi_list:, account: nil)
        @user = user
        @account = account
        @doi_list = doi_list
        @rejected_doi_list = []
      end

      def save
        doi_list&.compact&.each do |doi|
          next if doi.nil? || check_for_work_doi(doi)&.positive? || rejected_dois.include?(doi)

          fetch_and_create_work_with_doi(doi)
        end

        autopopulation_complete_notification
        queue_removal_of_non_open_access_doi
      end

      private

        def push_into_reject_doi_list(data)
          return if data["is_oa"]

          @rejected_doi_list << data["doi"]
        end

        def queue_removal_of_non_open_access_doi
          return if rejected_doi_list.empty?

          # Move non open access doi into the rejected_doi_list
          config.remove_non_open_access_doi_job.constantize.perform_later(account, rejected_doi_list)
        end

        def fetch_and_create_work_with_doi(doi)
          unpaywall_data = config.unpaywall_client.constantize.new(doi).data
          push_into_reject_doi_list(unpaywall_data)

          return unless unpaywall_data["is_oa"]&.present?

          work_data = fetch_crossref_work_data(doi)

          # adding the file url since crossref does not have it
          work_data[:unpaywall_pdf_url] = unpaywall_data.dig("best_oa_location", "url_for_pdf")
          config.create_work_class.constantize.new(work_data, user, account).save
        end

        def check_for_work_doi(doi)
          new_doi = slice_out_id_from_url(doi)

          # with escaping doi like 10.1016/S1296-2074(03)00005-0 are bad request
          doi_with_escaped_special_characters = RSolr.solr_escape(new_doi.downcase)

          return unless doi_with_escaped_special_characters.present?

          ActiveFedora::SolrService.count("doi_ssi: #{doi_with_escaped_special_characters}", rows: 1)
        end

        def fetch_crossref_work_data(doi)
          config.crossref_bolognese_client.constantize.new(input: doi)&.build_work_actor_attributes
        end

        def rejected_dois
          config.query_class.constantize.new(account).fetch_rejected_doi
        end

        def autopopulation_complete_notification
          url_path = Hyrax::Autopopulation::Engine.routes.url_helpers.work_fetchers_path(anchor: "draft-import")

          user.send_message(user, I18n.t("hyrax.autopopulation.notification.subject"),
                            I18n.t("hyrax.autopopulation.notification.body", url: url_path))
        end

        def config
          Rails.application.config.hyrax_autopopulation
        end
    end
  end
end
