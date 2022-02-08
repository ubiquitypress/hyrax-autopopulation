# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hyrax::Autopopulation::Dashboard::WorkFetchersController", type: :request do
  let(:config) { Rails.application.config.hyrax_autopopulation }
  let(:redis_storage) { config.redis_storage_class.constantize.new }
  let(:redis_instance) { Redis.new }
  let(:orcid_id) { "0000-0002-0787-9826A" }
  let(:route_helper) { Hyrax::Autopopulation::Engine.routes.url_helpers }
  let(:email) { "admin@example.com" }
  let(:user) { build_stubbed(:user, email: email) }
  let(:work_fetcher_job) { config.work_fetcher_job.constantize }

  before do
    allow(user).to receive(:groups).and_return(["admin"])
    allow(Redis).to receive(:new).and_return(redis_instance)
    allow(redis_instance).to receive(:sadd).and_return(true)
    allow(redis_instance).to receive(:scard).and_return([orcid_id])
    allow(redis_instance).to receive(:smembers).with("orcid_list").and_return([orcid_id])
    allow(redis_instance).to receive(:smembers).with("doi_list").and_return([])
    allow(redis_storage).to receive(:get_array).with("orcid_list").and_return([orcid_id])

    # prevents ActiveJob::DeserializationError caused by GlobalID::Locator.locate
    allow(User).to receive(:find).with(user.id.to_s).and_return(user)

    login_as(user, scope: :user)
  end

  context "GET /index" do
    before do
      WebMock.allow_net_connect!
    end
    it "Get /dashboard/work_fetchers/index" do
      get route_helper.work_fetchers_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "hyrax use case" do
    let(:id_type) { "doi" }
    let(:fetch_doi_args) { { fetch_doi_klass: config.query_class, user: user } }
    let(:fetch_doi_from_orcid_args) { { fetch_doi_klass: config.orcid_client, user: user } }

    context "POST /dashboard/work_fetchers/settings" do
      it "can save orcid id to redis" do
        post route_helper.settings_work_fetchers_path, params: { "settings" => { "orcid_list" => orcid_id, "doi_list" => " " } }
        expect(redis_storage.get_array("orcid_list")).to include(orcid_id)
        expect(response).to have_http_status(302)
      end
    end

    context "fetch data" do
      it "with doi will queue a job" do
        expect do
          post route_helper.fetch_with_doi_work_fetchers_path
        end.to have_enqueued_job(work_fetcher_job).with(fetch_doi_args).exactly(:once)
      end

      it "with orcid will queue a job" do
        expect do
          post route_helper.fetch_with_orcid_work_fetchers_path
        end.to have_enqueued_job(work_fetcher_job).with(fetch_doi_from_orcid_args).exactly(:once)
      end
    end

    context "approval" do
      let(:work) { build_stubbed(:work, title: ["work"], autopopulation_status: "draft") }

      before do
        allow(GenericWork).to receive(:find).with(work.id.to_s).and_return(user)
      end

      it "with submitted ids queues a job" do
        expect do
          put route_helper.approve_multiple_work_fetchers_path
        end.to have_enqueued_job(config.approval_job.constantize)
      end

      it "queues a job when approving all" do
        expect do
          put route_helper.approve_all_work_fetchers_path
        end.to have_enqueued_job(config.approval_job.constantize).with("all", user).exactly(:once)
      end
    end
  end
end
