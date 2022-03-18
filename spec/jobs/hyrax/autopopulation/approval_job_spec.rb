# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::ApprovalJob, type: :job do
  describe "create_work" do
    context "using hyrax" do
      let(:work) { create(:work, title: ["work"], autopopulation_status: "draft") }
      let(:work_1) { create(:work, title: ["work_1"], autopopulation_status: "draft") }
      let(:work_2) { create(:work, title: ["work_2"], autopopulation_status: "draft") }

      let(:email) { "admin@example.com" }
      let(:user) { build_stubbed(:user, email: email) }
      let(:approve_multiple_works) { ["multiple", user, [work.id]] }
      let(:approve_all_works) { ["all", user] }

      before do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
      end

      it "submitted ids can be used to approve works" do
        described_class.perform_now(*approve_multiple_works)
        expect(work.reload.autopopulation_status).to eq("approved")
      end

      it "all works with draft status can be approved" do
        expect { described_class.perform_now(*approve_all_works) }.to change { work_1.reload.autopopulation_status }.from("draft").to("approved")
      end
    end
  end
end
