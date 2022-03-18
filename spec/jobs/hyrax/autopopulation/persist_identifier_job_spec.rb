# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::PersistIdentifierJob, type: :job do
  let(:settings_hash) { { "settings" => { "doi_list" => "10.1016/j.crvasa.2015.05.007 https://handle.test.datacite.org/10.80090/nphc-8y78" } } }
  let(:args) { { data: settings_hash, account: nil } }

  context "hyrax app" do
    it "enqueues with settings_hash" do
      expect { described_class.perform_later(args) }.to have_enqueued_job(described_class).with(args)
    end
  end
end
