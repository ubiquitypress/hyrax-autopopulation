# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class PersistIdentifierJob < ApplicationJob
      # example of the value returned by args
      # {data: autopopulation_settings_params, account: account}
      # autopopulation_settings_params is a hash eg
      #
      def perform(args)
        config = Rails.application.config.hyrax_autopopulation
        config.persistence_class.constantize.new(**args).save
      end
    end
  end
end
