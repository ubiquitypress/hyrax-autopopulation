# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hyrax::Autopopulation::RedisStorage do
  describe "Persisting to Redis" do
    let(:config) { Rails.application.config.hyrax_autopopulation }
    let(:redis_storage) { config.redis_storage_class.constantize.new }
    let(:redis_instance) { Redis.new }
    let(:orcid_list) { ["0000-0002-0787-9826A"] }
    let(:doi_list) { ["10.36001/ijphm.2018.v9i1.2693"] }

    before do
      redis_storage.orcid_list = orcid_list
      redis_storage.orcid_list = doi_list
      redis_storage.save

      allow(Redis).to receive(:new).and_return(redis_instance)
      allow(redis_instance).to receive(:sadd).and_return(true)
      allow(redis_instance).to receive(:scard).and_return(orcid_list | doi_list)
      allow(redis_instance).to receive(:smembers).with("orcid_list").and_return(orcid_list)
      allow(redis_instance).to receive(:smembers).with("doi_list").and_return(doi_list)
    end

    context "save via redis_storage class" do
      it "orcid id to redis" do
        expect(redis_instance.smembers("orcid_list")).to eq orcid_list
      end

      it "doi to redis" do
        expect(redis_instance.smembers("doi_list")).to eq doi_list
      end
    end

    context "query for data via redis_storage class" do
      it "returns orcid_list" do
        expect(redis_storage.get_array("orcid_list")).to eq orcid_list
      end

      it "returns doi_list" do
        expect(redis_storage.get_array("doi_list")).to eq doi_list
      end
    end
  end
end
