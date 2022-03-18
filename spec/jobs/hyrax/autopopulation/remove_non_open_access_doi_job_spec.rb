# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::RemoveNonOpenAccessDoiJob, type: :job do
  describe "hyrax non open access doi" do
    let(:account) { build_stubbed(:account, cname: "repo") }
    let(:dois) { ["10.1016/j.crvasa.2015.05.007", "10.36001/ijphm.2018.v9i1.2693"] }

    before do
      # use by activejob to find the account
      allow(Account).to receive(:find).with(account.id.to_s).and_return(account)
    end

    it "can queue non openacess doi for Rejection" do
      expect { described_class.perform_later([account, dois]) }.to have_enqueued_job(described_class).with([account, dois])
    end
  end
end
