# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class Engine < ::Rails::Engine
      isolate_namespace Hyrax::Autopopulation

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: 'spec/factories'
      end

      config.before_initialize do
        Rails.application.routes.prepend do
          mount Hyrax::Autopopulation::Engine => "/"
        end
      end

      # Prepend our views so they have precedence
      config.after_initialize do
        ActionController::Base.prepend_view_path(paths['app/views'].existent)
      end

      # Allows us to access the configuration object from Rails application config
      #
      # Example
      # config = Rails.application.config.hyrax_autopopulation
      # config.redis_storage_class
      #
      initializer "hyrax autopopulation config", before: :load_config_initializers do |app|
        app.config.hyrax_autopopulation = Hyrax::Autopopulation::Configuration.new
        Hyrax::Autopopulation::Config = app.config.hyrax_autopopulation
      end
    end
  end
end
