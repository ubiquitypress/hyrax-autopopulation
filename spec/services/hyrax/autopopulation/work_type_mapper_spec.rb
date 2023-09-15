# frozen_string_literal: true


RSpec.describe Hyrax::Autopopulation::WorkTypeMapper do
  let(:crossref_types) { { types: [%w[resourceType journalArticle]] } }
  let(:crossref_hyku_mappings_with_missing_info) { { "book" => "Book", "grant" => "GrantRecord", "journal_article" => "" } }
  let(:crossref_hyku_mappings) { { "book" => "Book", "grant" => "GrantRecord", "journal_article" => "Article" } }


  context "map with type is not set" do
    it "returns GenericWork" do
      crossref_type = crossref_types[:types].to_h["resourceType"]&.underscore
      result = map_work_type(crossref_type, crossref_hyku_mappings_with_missing_info)
      expect(result).to eq("GenericWork")
    end
  end


  context "map with type is set" do
    it "returns the corresponding work type" do
      crossref_type = crossref_types[:types].to_h["resourceType"]&.underscore
      result = map_work_type(crossref_type, crossref_hyku_mappings)
      expect(result).to eq("Article")
    end
  end
end