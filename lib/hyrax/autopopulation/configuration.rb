# frozen_string_literal: true

# Leverages ActiveSupport Configurable
# Usage
# ======= Acesss ======
# Access attributes eg storage_type with class methods
# Hyrax::Autopopulation::Configuration.storage_type
#
# Access attributes eg storage_type with instance methods
# maded possible by adding config_acessor(:storage_type)
# Hyrax::Autopopulation::Configuration.new.storage_type
#
# ===== Settting  ======
# Hyrax::Autopopulation::Configuration.storage_type = "activerecord"
#  Or
# Hyrax::Autopopulation::Configuration.new.storage_type = "activerecord"
#
module Hyrax
  module Autopopulation
    class Configuration
      include ActiveSupport::Configurable

      config_accessor(:storage_type) { Object.const_defined?(:Account) ? "activerecord" : "redis" }
      config_accessor(:redis_storage_class) { "Hyrax::Autopopulation::RedisStorage" }
      config_accessor(:persistence_class) { "Hyrax::Autopopulation::RecordPersistence" }
      config_accessor(:is_hyrax_orcid_installed) { Object.const_defined?("OrcidIdentity") }
      config_accessor(:autopopulation_imported_work_status) { ["draft", "approved"] }
      config_accessor(:query_class) { "Hyrax::Autopopulation::RecordFetcher" }
      config_accessor(:create_work_class) { "Hyrax::Autopopulation::CreateWork" }
      config_accessor(:unpaywall_client) { "Hyrax::Autopopulation::UnpaywallClient" }
      config_accessor(:crossref_bolognese_client) { "Bolognese::Metadata" }
      config_accessor(:orcid_client) { "Hyrax::Autopopulation::OrcidClient" }
      config_accessor(:imported_work_status_service) { "Hyrax::Autopopulation::ImportedWorkStatusService" }
      config_accessor(:orchestrator_class) { "Hyrax::Autopopulation::Orchestrator" }
      config_accessor(:create_file_class) { "Hyrax::Autopopulation::CreateFile" }
      config_accessor(:work_fetcher_job) { "Hyrax::Autopopulation::WorkFetcherJob" }
      config_accessor(:approval_job) { "Hyrax::Autopopulation::ApprovalJob" }
      config_accessor(:fetch_and_save_work_metadata) { "Hyrax::Autopopulation::FetchAndSaveWorkMetadata" }
    end
  end
end
