# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Hyrax::Autopopulation::Dashboard::WorkFetchersController", type: :request do
  let(:config) { Rails.application.config.hyrax_autopopulation }
  let(:redis_storage) { config.redis_storage_class.constantize.new }
  let(:redis_instance) { Redis.new }
  let(:orcid_id) { "0000-0002-0787-9826A" }
  let(:route_helper) { Hyrax::Autopopulation::Engine.routes.url_helpers }
  let(:email) { "admin@example.com" }
  let(:user) { build_stubbed(:user, email: email) }

  before do
    allow(user).to receive(:groups).and_return(["admin"])
    allow(Redis).to receive(:new).and_return(redis_instance)
    allow(redis_instance).to receive(:sadd).and_return(true)
    allow(redis_instance).to receive(:scard).and_return([orcid_id])
    allow(redis_instance).to receive(:smembers).with("orcid_list").and_return([orcid_id])
    allow(redis_instance).to receive(:smembers).with("doi_list").and_return([])

    login_as(user, scope: :user)
  end

  context "GET /index" do
    it "Get /dashboard/work_fetchers/index" do
      get route_helper.work_fetchers_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "hyrax use case" do
    context "POST /dashboard/work_fetchers/settings" do
      it "can save orcid id to redis" do
        post route_helper.settings_work_fetchers_path, params: { "settings" => { "orcid_list" => orcid_id, "doi_list" => " " } }
        expect(redis_storage.get_array("orcid_list")).to eq([orcid_id])
        expect(redis_storage.get_array("doi_list")).to eq([])
        expect(response).to have_http_status(302)
      end
    end
  end
end
