# frozen_string_literal: true
module Hyrax
  module Autopopulation
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
