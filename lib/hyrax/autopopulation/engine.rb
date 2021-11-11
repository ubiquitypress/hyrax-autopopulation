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
    end
  end
end
