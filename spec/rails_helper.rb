# frozen_string_literal: true
# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
require File.expand_path("internal_test_hyrax/spec/rails_helper.rb", __dir__)
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("internal_test_hyrax/config/environment", __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "factory_bot_rails"
require "rspec/rails"
require "devise"
require "webmock/rspec"
require "active_fedora/cleaner"
require "noid/rails/rspec"

# Try and suppress depreciation warnings
ActiveSupport::Deprecation.silenced = true

allowed_hosts = %w[chrome chromedriver.storage.googleapis.com fcrepo solr]
WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_hosts)

Rails.application.routes.default_url_options[:host] = "www.example.com"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

def clean_active_fedora_repository
  ActiveFedora::Cleaner.clean!
  # The JS is executed in a different thread, so that other thread
  # may think the root path has already been created:
  ActiveFedora.fedora.connection.send(:init_base_path)
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Skip internal tests
  config.exclude_pattern = "./spec/internal_test_hyrax/spec/**/*_spec.rb"

  config.include ActiveSupport::Testing::TimeHelpers

  # Internal Tests to skip
  # Make sure this around is declared first so it runs before other around callbacks
  skip_internal_test_list = ["./spec/internal_test_hyrax/spec/features/create_generic_work_spec.rb"]
  config.around do |example|
    if skip_internal_test_list.include? example.file_path
      skip "Internal test skipped."
    else
      example.run
    end
  end

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Warden::Test::Helpers

  config.before do
    ActiveJob::Base.queue_adapter = :test
  end

  config.after do
    # Ensuring we have a clear queue between each spec.
    ActiveJob::Base.queue_adapter.enqueued_jobs  = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
  end

  config.before(:suite) do
    clean_active_fedora_repository
  end

  config.after do
    clean_active_fedora_repository
  end

  include Noid::Rails::RSpec
  config.before(:suite) { disable_production_minter! }
  config.after(:suite)  { enable_production_minter! }
end
