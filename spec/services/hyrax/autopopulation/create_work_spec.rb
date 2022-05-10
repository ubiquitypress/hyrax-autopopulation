# frozen_string_literal: true

RSpec.describe Hyrax::Autopopulation::CreateWork do
  describe "create_work" do
    let(:config) { Rails.application.config.hyrax_autopopulation }
    let(:email) { "admin@example.com" }
    let(:user) { build_stubbed(:user, email: email) }
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
        autopopulation_status: "draft", admin_set_id: "admin_set/default" }
    end

    let(:remote_file_url) { "http://x.com/pdf" }
    let(:file_set_id) { "bn999672v" }
    let(:file_set) { instance_double(FileSet, id: file_set_id, uri: "http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v") }
    let(:file) { Tempfile.new("test.pdf") }
    let(:uploaded_file) { Hyrax::UploadedFile.new(id: 1, user: user, file_set_uri: file_set.uri, file: file) }

    let(:subject) { described_class.new(attributes, user) }

    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let(:random_id) { SecureRandom.random_number(1_000_000) }
    let(:workflow) { Sipity::Workflow.new(id: random_id, name: "testing", permission_template: permission_template) }
    let(:sipity_workflow_action) { Sipity::WorkflowAction.new(id: random_id, name: "show", workflow_id: random_id) }

    let(:agent_access_manage) { { access: "manage", agent_type: "group" } }
    let(:agent_access_view) { { access: "manage", agent_type: "view" } }
    let(:agent_access_user) { { access: "manage", agent_type: "user" } }

    before do
      allow(Hyrax::PermissionTemplate).to receive(:find_by!).with(source_id: admin_set_id).and_return(permission_template)

      allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:agent_ids_for).with(agent_type: "group", access: "view").and_return([agent_access_view])
      allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:agent_ids_for).with(agent_type: "group", access: "manage").and_return([agent_access_manage])
      allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:agent_ids_for).with(agent_type: "user", access: "manage").and_return([agent_access_user])
      allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:agent_ids_for).with(agent_type: "user", access: "view").and_return([agent_access_view])
      allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:valid_visibility?).and_return(true)
      allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:access_grants).and_return(Hyrax::PermissionTemplateAccess)

      allow(Hyrax::Collections::PermissionsService).to receive(:source_ids_for_user).and_return(build_stubbed(:admin_set))
      allow_any_instance_of(Hyrax::PermissionTemplateApplicator).to receive(:apply_to).and_return(agent_access_manage)

      allow(Sipity::Workflow).to receive(:find_active_workflow_for).with(admin_set_id: admin_set_id).and_return(workflow)
      allow_any_instance_of(Hyrax::Workflow::WorkflowFactory).to receive(:find_deposit_action).and_return(sipity_workflow_action)
    end

    # test is ran in the context of Hyrax apps
    context "create work for hyrax apps", unless: defined?(::Hyku) do
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

    # test ran in the context of Hyku
    context "works are #inactive and not returned in search results", if: defined?(::Hyku) do
      let(:account) { build_stubbed(:account) }
      let(:state) { ::RDF::URI("http://fedora.info/definitions/1/0/access/ObjState#inactive") }
      let(:create_work) { described_class.new(attributes, user) }

      let(:creator) do
        [{ "creator_name_type" => "Personal", "creator_given_name" => "Liang", "creator_family_name" => "Gao" },
         { "creator_name_type" => "Personal", "creator_given_name" => "Chiye", "creator_family_name" => "Li" },
         { "creator_name_type" => "Personal", "creator_given_name" => "Yan", "creator_family_name" => "Liu" }]
      end

      let(:saved_work) { GenericWork.where(title: attributes[:title]).first }

      before do
        Hyrax::Autopopulation.configure do |config|
          config.storage_type = "activerecord"
        end

        allow(Account).to receive(:find).and_return(account)
        allow(AccountElevator).to receive(:switch!).and_return(true)

        attributes[:title] = ["check work is inactive and not returned in search"]
        attributes[:doi] = []
        attributes[:creator] = creator
        # temporarily set to empty to address: - can't modify frozen String: "2019"
        attributes[:date_published] = nil
        create_work.save
      end

      it "has attributes default state of inactive" do
        expect(subject.attributes[:state]).to eq(state)
      end

      it "creates work that are suppressed from search" do
        expect(saved_work).to be_suppressed
      end

      it "indexes works with state of inactive & sets the value of SOLR field suppressed_bsi to true" do
        expect(saved_work&.to_solr&.fetch("suppressed_bsi")).to be true
      end
    end
  end
end
