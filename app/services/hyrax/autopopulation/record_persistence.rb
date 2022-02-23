# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class RecordPersistence
      include Hyrax::Autopopulation::ParseIdentifier

      attr_accessor :data, :account, :works

      def initialize(account: nil, data: nil, works: nil)
        AccountElevator.switch!(account.cname) if config.active_record?

        @account = account
        @data = data
        @works = works
      end

      # A wrapper that allows saving to Redis when using Hyrax & to  Activerecord for Hyku
      # data is hash that has
      # 3 keys doi_list and orcid_list are arrays & hyrax_orcid_settings is a hash
      #
      #   Example
      #
      # { "settings" => { "orcid_list" => ["0000-0002-0787-9826A"],
      #                   "doi_list" => ["10.36001/ijphm.2018.v9i1.2693"],
      #                    "hyrax_orcid_settings" => { } }
      # }
      #
      def save
        if account.present?
          save_to_postgres
        else
          save_to_redis
        end
      end

      # Imported works can have a status of either :approved  or :draft
      # Newly imported works start with a status of draft and visibility set to :restricted
      #
      # This method receives an array of imported work and update their status
      # Emanple
      #
      # [<GenericWork>, <Article>]
      #
      def approved_works
        works&.compact&.each do |work|
          work&.file_sets&.first&.update(visibility: "open")
          work.update(autopopulation_status: "approved", visibility: "open")
        end
      end

      def delete_rejected_works
        works&.each do |work|
          work.destroy
        end
      end

      # takes doi ids of rejected works
      def save_rejected_ids
        doi_ids = works&.map { |work| work&.doi&.first }

        return unless doi_ids.present?

        save_rejected_work_ids(doi_ids)
        # so we can do chained method call
        self
      end

      private

        def config
          Rails.application.config.hyrax_autopopulation
        end

        def save_rejected_work_ids(doi_ids)
          if account.present?
            existing_doi = Array.wrap(account.settings["doi_list"])
            remaining_ids = existing_doi - doi_ids
            account.settings["doi_list"] = remaining_ids
            account.settings["rejected_doi_list"] = doi_ids
            account.save
          else
            # remove rejected ids from ids used for fetching works netatdata
            config.redis_storage_class.constantize.new.remove_from_array("doi_list", doi_ids)
            config.redis_storage_class.constantize.new.set_array("rejected_doi_list", doi_ids)
          end
        end

        def save_to_postgres
          return unless account.present?

          AccountElevator.switch!(account.cname)

          doi_list = extract_doi_for_hyku
          orcid_list = extract_orcid_for_hyku
          orcid_settings = hyku_set_hyrax_orcid_settings

          account.settings["hyrax_orcid_settings"] = orcid_settings
          account.settings.merge!("doi_list" => doi_list, "orcid_list" => orcid_list)
          account.settings.compact
          account.save
        end

        # eg data a hash and key a string must be doi_list or orcid_list
        def split_string(key)
          str = data&.dig("settings", key)
          str&.strip&.gsub("\\n", " ")&.split(/[,\s]+/)
        end

        def extract_doi_for_hyku
          existing_doi = Array.wrap(account.settings["doi_list"])
          new_doi = split_string("doi_list")&.presence || []
          doi_ids = remove_url_from_ids(new_doi)

          existing_doi | doi_ids
        end

        def extract_orcid_for_hyku
          existing_orcid = Array.wrap(account.settings["orcid_list"])
          sync_orcid = existing_orcid.blank? ? config.query_class.constantize.new(account).synced_orcid_identity : []
          new_orcid = split_string("orcid_list")&.presence || []
          orcid_ids = remove_url_from_ids(new_orcid)
          existing_orcid | orcid_ids | sync_orcid
        end

        def hyku_set_hyrax_orcid_settings
          hash = data&.dig("settings", "hyrax_orcid_settings")&.presence || {}
          account.settings["hyrax_orcid_settings"].merge(hash)
        end

        def orcid_for_hyrax_app
          existing_orcid = config.redis_storage_class.constantize.new.get_array("orcid_list")
          existing_orcid = existing_orcid.blank? ? config.query_class.constantize.new.synced_orcid_identity : []

          new_orcid = split_string("orcid_list").presence || []

          existing_orcid | new_orcid
        end

        def save_to_redis
          new_doi = split_string("doi_list")&.presence || []
          doi_ids = remove_url_from_ids(new_doi)

          new_orcid = orcid_for_hyrax_app
          orcid_ids = remove_url_from_ids(new_orcid)

          hyrax_orcid_settings = data&.dig("settings", "hyrax_orcid_settings").presence || {}

          config.redis_storage_class.constantize.new(doi_list: doi_ids, orcid_list: orcid_ids, hyrax_orcid_settings: hyrax_orcid_settings).save
        end
    end
  end
end
