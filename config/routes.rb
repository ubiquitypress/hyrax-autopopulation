# frozen_string_literal: true
Hyrax::Autopopulation::Engine.routes.draw do
  scope :dashboard do
    resources :work_fetchers, only: [:index], controller: "/hyrax/autopopulation/dashboard/work_fetchers" do
      collection do
        patch :settings
        post :settings
        post :fetch_with_doi
        post :fetch_with_orcid
        put :approve_multiple
        put :approve_all
      end
    end
  end
end
