# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::Configuration do
  let(:config) { Rails.application.config.hyrax_autopopulation }
  let(:storage_type) { "redis" }
  let(:redis_storage_class) { "Hyrax::Autopopulation::RedisStorage" }
  let(:persistence_class) { "Hyrax::Autopopulation::RecordPersistence" }
  let(:is_hyrax_orcid_installed) { false }
  let(:autopopulation_imported_work_status) { ["draft", "approved"] }

  context "with defaults" do
    before do
      Hyrax::Autopopulation.reset
    end

    it "returns :storageType" do
      expect(subject.storage_type).to eq(storage_type)
    end

    it "returns :redis_storage_class" do
      expect(subject.redis_storage_class).to eq(redis_storage_class)
    end

    it "returns :persistence_class" do
      expect(subject.persistence_class).to eq(persistence_class)
    end

    it "returns :autopopulated_imported_work_status" do
      expect(config.autopopulation_imported_work_status).to eq(autopopulation_imported_work_status)
    end

    it "checks if active_record is storage_type" do
      expect(config.active_record?).to be_falsey
    end
  end

  context "can be customised" do
    before do
      Hyrax::Autopopulation.configure do |config|
        config.is_hyrax_orcid_installed = true
        config.autopopulation_imported_work_status = ["draft"]
      end
    end

    it "does not return default :storage_type" do
      expect(Hyrax::Autopopulation.configuration.autopopulation_imported_work_status).not_to eq(autopopulation_imported_work_status)
    end

    it "does not return :is_hyrax_installed" do
      expect(config.is_hyrax_orcid_installed).not_to eq(is_hyrax_orcid_installed)
    end

    it "can return :storage_type" do
      expect(config.autopopulation_imported_work_status).to eq(["draft"])
    end

    it "can return correct is_hyrax_installed" do
      expect(Hyrax::Autopopulation.configuration.is_hyrax_orcid_installed).to eq(true)
    end

    it "returns unchnaged attributes eg :persistence_class" do
      expect(config.persistence_class).to eq(persistence_class)
    end
  end
end
