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
      # { "settings" => {
      #      "orcid_list" => ["0000-0002-0787-9826A"],
      #       "doi_list" => ["10.36001/ijphm.2018.v9i1.2693"],
      #        "hyrax_orcid_settings" => { }
      #  }
      #  }
      #
      def save(data, account = nil)
        @data = data
        @account = account

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
      def approved_works(works)
        works.each do |work|
          work.update(autopopulation_status: "approved", visibility: "open")
        end
      end

      def save_orcid_details(hash)
        if config.storage_type == "activerecord"
          AccountElevator.switch!(account.cname)
          orcid_settings = account.settings["hyrax_orcid_settings"].merge(hash)
          account.settings["hyrax_orcid_settings"] = orcid_settings
          account.save
        else
          config.redis_storage_class.constantize.new(hyrax_orcid_settings: hash).save
        end
      end

      private

        def config
          Rails.application.config.hyrax_autopopulation
        end

        def save_to_postgres(data, account)
          return unless account.present?

          AccountElevator.switch!(account.cname)
          existing_doi = account.settings["doi_list"]
          new_doi = data["settings"]["doi_list"].split(" ")
          doi_list = existing_doi | new_doi

          existing_orcid = account.settings["orcid_list"]
          new_orcid = data["settings"]["orcid_list"].split(" ")
          orcid_list = existing_orcid | new_orcid

          account.settings.merge!("doi_list" => doi_list, "orcid_list" => orcid_list)
          account.settings.compact
          account.save
        end

        def save_to_redis(data)
          new_doi = data["settings"]["doi_list"].split(" ")
          new_orcid = data["settings"]["orcid_list"].split(" ")
          config.redis_storage_class.constantize.new(doi_list: new_doi, orcid_list: new_orcid).save
        end
    end
  end
end
