# frozen_string_literal: true
require "hyrax/autopopulation/engine"
require "hyrax/autopopulation/configuration"

require "bolognese"

module Hyrax
  module Autopopulation
    class << self
      attr_writer :configuration
    end

    # Note Hyrax::Autopopulation::Config is set in the rails engine initializer
    # Usage
    # Assumming you want to access storage_type
    # You can either use
    # Hyrax::Autopopulation.configuration.storage_type
    #
    # ======   or use ========
    #
    # config = Rails.application.config.hyrax_autopopulation
    # config.storage_type
    #
    def self.configuration
      @configuration = Rails.application.config.hyrax_autopopulation
    end

    # Resets to using defaults value
    def self.reset
      Rails.application.config.hyrax_autopopulation = Configuration.new
    end

    #  Exposes Hyrax Autopopulaton configuration
    # @yield [Hyrax::Autopopulation::Configuration] if a block is passed
    #
    #  Usage
    #  Hyrax::Autopopulation.configure do |config|
    #    config.is_hyrax_orcid_installed = true
    #  end
    #
    # Note Hyrax::Autopopulation::Config is set in the rails engine initializer
    #
    def self.configure
      yield(Rails.application.config.hyrax_autopopulation)
    end
  end
end
