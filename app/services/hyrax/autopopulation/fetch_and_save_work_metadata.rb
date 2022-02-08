# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class FetchAndSaveWorkMetadata
      attr_accessor :user, :account, :doi_list

      def initialize(user:, doi_list:, account: nil)
        @user = user
        @account = account
        @doi_list = doi_list
      end

      def save
        doi_list&.compact&.each do |doi|
          next if doi.nil? || check_for_work_doi(doi).positive?

          fetch_and_create_work_with_doi(doi)
        end

        autopopulation_complete_notification
      end

      private

        def fetch_and_create_work_with_doi(doi)
          unpaywall_data = config.unpaywall_client.constantize.new(doi).data

          return unless unpaywall_data["is_oa"]&.present?

          work_data = fetch_crossref_work_data(doi)

          # adding the file url since crossref does not have it
          work_data[:unpaywall_pdf_url] = unpaywall_data.dig("best_oa_location", "url_for_pdf")

          config.create_work_class.constantize.new(work_data, user, account&.cname).save
        end

        def check_for_work_doi(doi)
          ActiveFedora::SolrService.count("doi_ssi: #{doi}", rows: 1)
        end

        def fetch_crossref_work_data(doi)
          response = config.crossref_bolognese_client.constantize.new(input: doi)
          response.build_work_actor_attributes
        end

        def autopopulation_complete_notification
          user.send_message(user, "autopopulation - Import completed", "work autopopulation")
        end

        def config
          Rails.application.config.hyrax_autopopulation
        end
    end
  end
end
