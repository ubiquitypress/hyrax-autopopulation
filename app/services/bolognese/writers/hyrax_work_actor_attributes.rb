# frozen_string_literal: true

module Bolognese
  module Writers
    module HyraxWorkActorAttributes
      include Hyrax::Autopopulation::WorkTypeMapper

      def build_work_actor_attributes
        {
          doi: Array(meta["doi"]),
          title: meta["titles"].pluck("title"), date_published: write_actor_date_published,
          publisher: Array.wrap(meta["publisher"]),
          creator: write_actor_json_field("creator"),
          contributor: write_actor_json_field("contributor"),
          resource_type: write_actor_resource_type,
          visibility: "open", autopopulation_status: "draft"
        }
      end

      def build_crossref_types
        {
          types: Array(meta["types"])
        }
      end

      private

        # type eg creators, contributors, editors
        def write_actor_json_field(key_type)
          key_type = key_type.to_s.downcase
          crossref_hyku_mappings = Site.account.settings&.dig("crossref_hyku_mappings")
          @mapped_work_type = map_work_type(meta["types"].dig("resourceType")&.underscore, crossref_hyku_mappings)
          if Object.const_defined?(@mapped_work_type) && Object.const_get(@mapped_work_type).method_defined?(:json_fields)
            meta[key_type.pluralize].each_with_index.inject([]) do |array, (hash, index)|
              hash["#{key_type}_position"] = index
              hash["#{key_type}_name_type"] = hash["nameType"]
              hash["#{key_type}_given_name"] = hash["givenName"]
              hash["#{key_type}_family_name"] = hash["familyName"]
              array << hash.slice("#{key_type}_name_type", "#{key_type}_given_name", "#{key_type}_family_name",
                                  "#{key_type}_position")
            end
          else
            meta[key_type.pluralize].inject([]) { |array, hash| array << "#{hash['givenName']}, #{hash['familyName']}" }
          end
        end

        def editor_check(key_type, hash)
          return if key_type == "contributor" && !hash["contributorType"] == "Editor"
          # key_type = "editor"
        end

        def write_actor_resource_type
          type = meta["types"].dig("resourceType")&.titleize
          crossref_hyku_mappings = Site.account.settings&.dig("crossref_hyku_mappings")
          @mapped_work_type = map_work_type(meta["types"].dig("resourceType")&.underscore, crossref_hyku_mappings)

          options = if Object.const_defined?("HykuAddons::ResourceTypesService")
                      ::HykuAddons::ResourceTypesService.new(model: Object.const_get(@mapped_work_type)).select_active_options.flatten.uniq
                      # options.include?(type) ? Array.wrap(type) : ["Other"]
                    else
                      ::Hyrax::ResourceTypesService.select_options.flatten.uniq
                      # options.include?(type) ? Array.wrap(type) : ["Other"]
                    end
          options.include?(type) ? Array.wrap(type) : ["Other"]
        end

        def write_actor_date_published
          date = get_year_month_day(date_registered)
          Array.wrap("date_published_year" => date&.first&.to_s, "date_published_month" => date[1]&.to_s, "date_published_day" => date&.last&.to_s)
        end
    end
  end
end
