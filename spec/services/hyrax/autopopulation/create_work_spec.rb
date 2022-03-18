# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::CreateWork do
  describe "create_work" do
    let(:config) { Rails.application.config.hyrax_autopopulation }
    let(:email) { "admin@example.com" }
    let(:user) { build_stubbed(:user, email: email) }
    let(:work) { build(:work) }
    let(:work_2) { build(:work) }
    let(:ability) { ::Ability.new(user) }
    let(:actor) { Hyrax::CurationConcern.actor }
    let(:actor_environment) { Hyrax::Actors::Environment.new(work, ability, attributes) }

    let(:attributes) do
      { doi: ["10.1038/srep15737"],
        title: ["Fiber-optic control and thermometry of single-cell thermosensation logic"],
        date_published: [{ "date_published_year" => "2019",
                           "date_published_month" => "10",
                           "date_published_day" => "9" }],
        publisher: ["Springer Science and Business Media LLC"],
        creator: ["I.V., Fedotov", "N.A., Safronov", "Yu.G., Ermakova",
                  "M.E., Matlashov", "D.A., Sidorov-Biryukov", "A.B., Fedotov",
                  "V.V., Belousov", "A.M., Zheltikov"],
        contributor: [], editor: [],
        resource_type: ["Other"], visibility: "restricted",
        autopopulation_status: "draft" }
    end

    let(:remote_file_url) { "http://x.com/pdf" }
    let(:file_set_id) { "bn999672v" }
    let(:file_set) { instance_double(FileSet, id: file_set_id, uri: "http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v") }
    let(:file) { Tempfile.new("test.pdf") }
    let(:uploaded_file) { Hyrax::UploadedFile.new(id: 1, user: user, file_set_uri: file_set.uri, file: file) }

    let(:subject) { described_class.new(attributes, user) }

    context "create work for hyrax apps" do
      before do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        allow(Hyrax::UploadedFile).to receive(:find).with(1.to_s).and_return(uploaded_file)
        allow(Hyrax::UploadedFile).to receive(:create).and_return(uploaded_file)
        allow_any_instance_of(config.create_file_class.constantize).to receive(:save).and_return(uploaded_file)
      end

      it "creates a new work" do
        expect { subject.save }.to change { GenericWork.count }.by(1)
      end

      it "adds file from remote url" do
        attributes[:unpaywall_pdf_url] = remote_file_url
        allow(actor).to receive(:create) { true }
        new_instance = described_class.new(attributes, user)
        expect(new_instance.attributes[:uploaded_file]).to eq([uploaded_file.id])
      end
    end
  end
end
