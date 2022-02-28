# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class RemoveNonOpenAccessDoiJob < ApplicationJob
      def perform(account, doi_list)
        config = Rails.application.config.hyrax_autopopulation
        klass = config.persistence_class.constantize.new(account: account, rejected_doi: doi_list)
        klass.save_rejected_ids
      end
    end
  end
end
