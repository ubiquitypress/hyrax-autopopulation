# frozen_string_literal: true
Hyrax::Autopopulation::Engine.routes.draw do
  scope :dashboard do
    resources :work_fetchers, only: [:index], controller: "/hyrax/autopopulation/dashboard/work_fetchers" do
      collection do
        patch :settings
        post :settings
      end
    end
  end
end
