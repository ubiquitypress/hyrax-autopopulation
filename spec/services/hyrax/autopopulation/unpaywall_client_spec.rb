# frozen_string_literal: true

RSpec.describe ::Hyrax::Autopopulation::UnpaywallClient do
  let(:config) { Rails.application.config.hyrax_autopopulation }
  let(:doi) { "10.36001/ijphm.2018.v9i1.2693" }
  let(:email) { "unpaywall_01@example.com" }
  let(:enginer_root) { Hyrax::Autopopulation::Engine.root }
  let(:unpaywall_response_body) { File.read(enginer_root.join("spec", "fixtures", "unpaywall10.1117_12.2004063.json")) }
  let(:subject) { config.unpaywall_client.constantize.new(doi) }
  before do
    stub_request(:get, "#{Hyrax::Autopopulation::UnpaywallClient::ENDPOINT}/#{doi}?email=unpaywall_01@example.com")
      .with(
        headers: {
          "Accept": "*/*",
          "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type": "application/json",
          "User-Agent": "Faraday v0.17.4"
        }
      )
      .to_return(status: 200, body: unpaywall_response_body, headers: {})
  end

  it "can fetch metatadata from unpaywall" do
    expect(subject.data).to be_a(Hash)
    expect(subject.data).not_to be_empty
  end
end
