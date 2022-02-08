# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Hyrax::Autopopulation::OrcidClient do
  let(:config) { Rails.application.config.hyrax_autopopulation }
  let(:enginer_root) { Hyrax::Autopopulation::Engine.root }
  let(:subject) { config.orcid_client.constantize.new }
  let(:orcid_id) { "0000-0002-0787-9826" }
  let(:orcid_response_body) { File.read(enginer_root.join("spec", "fixtures", "orcid_0000-0002-0787-9826.json")) }

  let(:orcid_url) { Hyrax::Autopopulation::OrcidClient::ORCID_API_URL }
  let(:endpoint) { Hyrax::Autopopulation::OrcidClient::ENDPOINT }

  let(:redis_storage_instance) { config.redis_storage_class.constantize.new }

  let(:hyrax_orcid_settings) do
    { "access_token" => "24e15c94-fcf6-4504-a3c0-46d47df36faa",
      "token_type" => "bearer",
      "refresh_token" => "ca01054f-0432-4563-8d5d-8d0fff047d01",
      "expires_in" => "631138518",
      "scope" => "/read-public" }
  end

  let(:faraday_response) { instance_double(Faraday::Response, success?: true, body: orcid_response_body) }

  before do
    allow(redis_storage_instance).to receive(:get_hash).with("hyrax_orcid_settings").and_return(hyrax_orcid_settings)
    allow(config.query_class.constantize.new).to receive(:orcid_from_db).and_return([orcid_id])
    allow(subject).to receive(:fetch_works_with_auth).and_return([faraday_response])
  end

  it "returns doi" do
    expect(subject.fetch_doi_list).to eq(%w[10.1038/srep15737 10.1038/nature12373 10.1117/12.2004063])
  end
end
