# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class RecordPersistence
      attr_accessor :data, :account

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
      def save(data, account = nil)
        if account.present?
          save_to_postgres(data, account)
        else
          save_to_redis(data)
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
      def approved_works(works, account = nil)
        AccountElevator.switch!(account.cname) if config.storage_type == "activerecord"
        works&.compact&.each do |work|
          work&.file_sets&.first&.update(visibility: "open")
          work.update(autopopulation_status: "approved", visibility: "open")
        end
      end

      private

        def config
          Rails.application.config.hyrax_autopopulation
        end

        def save_to_postgres(data, account)
          return unless account.present?

          AccountElevator.switch!(account.cname)

          doi_list = extract_doi_for_hyku(account)
          orcid_list = extract_orcid_for_hyku(account)
          orcid_settings = hyku_set_hyrax_orcid_settings(data, account)

          account.settings["hyrax_orcid_settings"] = orcid_settings
          account.settings.merge!("doi_list" => doi_list, "orcid_list" => orcid_list)
          account.settings.compact
          account.save
        end

        def extract_doi_for_hyku(account)
          existing_doi = Array.wrap(account.settings["doi_list"])
          new_doi = data&.dig("settings")&.dig("doi_list")&.split(" ").presence || []
          existing_doi | new_doi
        end

        def extract_orcid_for_hyku(account)
          existing_orcid = Array.wrap(account.settings["orcid_list"])
          existing_orcid = existing_orcid.blank? ? config.query_class.constantize.new.synced_orcid_identity : []
          new_orcid = data&.dig("settings")&.dig("orcid_list")&.split(" ").presence || []
          existing_orcid | new_orcid
        end

        def hyku_set_hyrax_orcid_settings(data, account)
          hash = data&.dig("settings")&.dig("hyrax_orcid_settings")&.symbolize_keys&.presence || {}
          account.settings["hyrax_orcid_settings"].merge(hash)
        end

        def orcid_for_hyrax_app
          existing_orcid = config.redis_storage_class.constantize.new.get_array("orcid_list")
          existing_orcid = existing_orcid.blank? ? config.query_class.constantize.new.synced_orcid_identity : []

          orcid_id = data&.dig("settings")&.dig("orcid_list")&.split(" ").presence || []

          existing_orcid | orcid_id
        end

        def save_to_redis(data)
          new_doi = data&.dig("settings")&.dig("doi_list")&.split(" ").presence || []
          new_orcid = new_orcid

          hyrax_orcid_settings = data&.dig("settings")&.dig("hyrax_orcid_settings").presence || {}

          config.redis_storage_class.constantize.new(doi_list: new_doi, orcid_list: new_orcid, hyrax_orcid_settings: hyrax_orcid_settings).save
        end
    end
  end
end
