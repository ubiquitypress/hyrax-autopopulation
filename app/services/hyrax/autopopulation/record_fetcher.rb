# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class RecordFetcher
      attr_accessor :account

      def initialize(account = nil)
        AccountElevator.switch!(account.cname) if config.active_record?
        @account = account
      end

      def orcid_from_db
        fetch_by("orcid_list")&.presence || []
      end

      # Calls out to ::Hyrax::Autopopulation::RedisStorage.new.get_array("doi_list")
      def fetch_doi_list
        fetch_by("doi_list")&.presence || []
      end

      def fetch_rejected_doi
        fetch_by("rejected_doi_list")&.presence || []
      end

      # only fetch the sunced orcid id if an orcid identity_table exists?
      def synced_orcid_identity
        return [] unless config.is_hyrax_orcid_installed

        ids = ::OrcidIdentity.exists? && OrcidIdentity.all.map(&:orcid_id).compact
        ids.presence || []
      end

      def fetch_by_ids(work_ids)
        @fetch_by_ids ||= ActiveFedora::Base.where("{!terms f=id}#{work_ids.join(',')}")
      end

      def fetch_all_draft
        @fetch_all_draft ||= ActiveFedora::Base.where("autopopulation_status_tesim:draft")
      end

      def fetch_by(key)
        if config.active_record? && Object.const_defined?(:Account)
          account.settings.dig(key)
        else
          config.redis_storage_class.constantize.new.get_array(key)
        end
      end

      private

        def config
          Rails.application.config.hyrax_autopopulation
        end
    end
  end
end
