# frozen_string_literal: true

require "bolognese/metadata"

module Hyrax
  module Autopopulation
    class Engine < ::Rails::Engine
      isolate_namespace Hyrax::Autopopulation

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: "spec/factories"
      end

      # Allow flipflop to load config/features.rb from the Hyrax gem:
      initializer "configure" do
        Flipflop::FeatureLoader.current.append(self)
      end

      config.before_initialize do
        Rails.application.routes.prepend do
          mount Hyrax::Autopopulation::Engine => "/"
        end
      end

      # Prepend our views so they have precedence
      config.after_initialize do
        ActionController::Base.prepend_view_path(paths["app/views"].existent)

        ::Hyrax::Actors::DOIActor.prepend(Hyrax::Autopopulation::DoiActorOverride) if Object.const_defined? "Hyrax::Actors::DOIActor"
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

      # Pre-existing Work type overrides and dynamic includes
      def self.mixins
        ::Bolognese::Metadata.prepend ::Bolognese::Writers::HyraxWorkActorAttributes

        if config.hyrax_autopopulation.app_name != "hyku_addons"
          ::Hyrax::BasicMetadata.include(Hyrax::Autopopulation::AutopopulationProperty)
          ::Hyrax::BasicMetadata.include(Hyrax::Autopopulation::DoiProperty)
          ::Hyrax::SolrDocumentBehavior.include(Hyrax::Autopopulation::SolrDocumentBehavior)
        end
      end

      # Use #to_prepare because it reloads where after_initialize only runs once
      # This might slow down every request so only do it in development environment
      method = Rails.env.development? ? :to_prepare : :after_initialize
      config.send(method) { Hyrax::Autopopulation::Engine.mixins }
    end
  end
end
