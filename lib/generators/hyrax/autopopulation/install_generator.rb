# frozen_string_literal: true

module Hyrax
  module Autopopulation
    class InstallGenerator < Rails::Generators::Base
      def add_to_sidebar
        path = %w[app views hyrax dashboard sidebar _repository_content.html.erb]

        if Object.const_defined?(:HykuAddons)
          file_path_to_add_content = File.join(::HykuAddons::Engine.root.to_s, *path)
        elsif Object.const_defined?(:Hyku)
          file_path_to_add_content = File.join(Rails.root.to_s, *path)
        elsif Object.const_defined?(:Hyrax) && !Object.const_defined?(:Hyku) && !Object.const_defined?(:HykuAddons)
          file_path_to_add_content = File.join(::Hyrax::Engine.root.to_s, *path)
        end

        append_to_file file_path_to_add_content do
          <<-"RUBY"
            <%= render "hyrax/autopopulation/dashboard/work_fetchers/sidebar/autopopulation", menu: menu %>
          RUBY
        end
      end
    end
  end
end
