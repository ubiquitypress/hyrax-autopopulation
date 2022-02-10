# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class Orchestrator
      attr_accessor :user, :account, :save_metadata_klass, :fetch_doi_klass

      def initialize(fetch_doi_klass:, save_metadata_klass: nil, user:, account: nil)
        AccountElevator.switch!(account.cname) if config.storage_type == "activerecord"

        @user = user
        @account = account
        @fetch_doi_klass = fetch_doi_klass
        @save_metadata_klass = save_metadata_klass.presence || config.fetch_and_save_work_metadata
        @fetch_doi_list = []
      end

      def fetch_doi_list
        klass = fetch_doi_klass.constantize.new(account)
        return [] unless klass.respond_to?(:fetch_doi_list)

        @fetch_doi_list = Array.wrap(klass.fetch_doi_list.presence)
      end

      # Hyrax::Autopopulation::FetchAndSaveWorkMetadata.new(user).save(list_of_doi)
      def create_records
        klass = save_metadata_klass.constantize.new(user: user, doi_list: fetch_doi_list, account: account)
        return unless fetch_doi_list.present? && klass.respond_to?(:save)

        klass.save
      end

      private

        def config
          Rails.application.config.hyrax_autopopulation
        end
    end
  end
end
