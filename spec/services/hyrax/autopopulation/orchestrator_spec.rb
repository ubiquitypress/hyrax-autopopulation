# frozen_string_literal: true

RSpec.describe ::Hyrax::Autopopulation::Orchestrator do
  describe "call multiple api " do
    let(:config) { Rails.application.config.hyrax_autopopulation }
    let(:enginer_root) { Hyrax::Autopopulation::Engine.root }

    let(:email) { "admin@example.com" }
    let(:user) { build_stubbed(:user, email: email) }

    let(:unpaywall_client) { config.unpaywall_client.constantize }
    let(:unpaywall_instance) { config.unpaywall_client.constantize.new(submitted_doi.first) }
    let(:unpaywall_response_body) { File.read(enginer_root.join("spec", "fixtures", "unpaywall10.1117_12.2004063.json")) }

    let(:query_class_instance) { config.query_class.constantize.new }
    let(:submitted_doi) { ["10.36001/ijphm.2018.v9i1.2693"] }

    let(:crossref_response_body) { File.read(enginer_root.join("spec", "fixtures", "crossref_10.1117_12.2004063.json")) }
    let(:crossref_bolognese_client) { config.crossref_bolognese_client.constantize }
    let(:bolognese_metadata) { Bolognese::Metadata.new(input: crossref_response_body) }

    context "with hyrax" do
      before do
        allow(query_class_instance).to receive(:fetch_doi_list).and_return(submitted_doi)
        allow_any_instance_of(config.query_class.constantize).to receive(:fetch_doi_list).and_return(submitted_doi)
        allow_any_instance_of(config.orcid_client.constantize).to receive(:fetch_doi_list).and_return(["10.1038/srep15737"])
      end

      it "retruns already saved doi" do
        args = { user: user, fetch_doi_klass: config.query_class }
        object = described_class.new(**args)
        expect(object.fetch_doi_list).to eq(submitted_doi)
      end

      it "fetches doi using orcid" do
        args = { user: user, fetch_doi_klass: config.orcid_client }
        object = described_class.new(**args)
        expect(object.fetch_doi_list).to eq(["10.1038/srep15737"])
      end
    end

    context "create works" do
      before do
        allow(unpaywall_client).to receive(:new).with(submitted_doi.first).and_return(unpaywall_instance)
        allow_any_instance_of(unpaywall_client).to receive(:data).and_return(JSON.parse(unpaywall_response_body))

        allow(crossref_bolognese_client).to receive(:new).and_return(bolognese_metadata)
        # allow_any_instance_of(config.create_work_class.constantize).to receive(:save).and_return(true)
        allow_any_instance_of(config.orcid_client.constantize).to receive(:fetch_doi_list).and_return(submitted_doi)
        allow_any_instance_of(config.create_file_class.constantize).to receive(:save).and_return(nil)
      end

      it "can create work using doi metatdata" do
        args = { user: user, fetch_doi_klass: config.orcid_client }
        object = described_class.new(**args)
        object.fetch_doi_list
        expect { object.create_records }.to change { GenericWork.count }.by(1)
      end
    end
  end
end
