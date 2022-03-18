# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::ParseIdentifier do
  let(:mixed_dois) { [doi, doi_url] }
  let(:doi_url) { "https://handle.test.datacite.org/#{doi_1}" }
  let(:doi) { "10.1629/uksg.236" }
  let(:doi_1) { "10.80090/nphc-8y78" }
  let(:parsed_ids) { [doi, doi_1] }

  class DummyClass
    include Hyrax::Autopopulation::ParseIdentifier
  end

  let(:klass) { DummyClass.new }

  context "mixed array of ids and url with ids" do
    it "can return array of ids" do
      expect(klass.send(:remove_url_from_ids, mixed_dois)).to eq(parsed_ids)
    end
  end

  context "given a doi url" do
    it "can return the id" do
      expect(klass.send(:slice_out_id_from_url, doi_url)).to eq(doi_1)
    end
  end
end
