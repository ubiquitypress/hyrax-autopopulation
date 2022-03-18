# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::RejectionJob, type: :job do
  describe "hyrax rejection" do
    let(:work) { create(:work, title: ["work"], autopopulation_status: "draft") }

    it "can queue RejectionJob" do
      expect { described_class.perform_later([work.id]) }.to have_enqueued_job(described_class).with([work.id])
    end
  end
end
