# frozen_string_literal: true

RSpec.describe Bolognese::Writers::HyraxWorkActorAttributes do
  let(:attributes) do
    { doi: ["10.1117/12.2004063"],
      title: ["Single-cell photoacoustic thermometry"],
      date_published: [{ "date_published_year" => "2015",
                         "date_published_month" => "5",
                         "date_published_day" => "29" }],
      publisher: ["SPIE-Intl Soc Optical Eng"],
      creator: ["Liang, Gao", "Lidai, Wang",
                "Chiye, Li", "Yan, Liu", "Haixin, Ke",
                "Chi, Zhang", "Lihong V., Wang"],
      contributor: ["Alexander A., Oraevsky", "Lihong V., Wang"],
      editor: ["Alexander A., Oraevsky", "Lihong V., Wang"],
      resource_type: ["Other"],
      visibility: "restricted",
      autopopulation_status: "draft" }
  end

  let(:crossref_response) { File.read(Hyrax::Autopopulation::Engine.root.join("spec", "fixtures", "crossref_10.1117_12.2004063.json")) }

  let(:metadata_class) do
    Class.new(Bolognese::Metadata) do
      include Bolognese::Writers::HyraxWorkActorAttributes
    end
  end

  let(:metadata) { metadata_class.new(input: crossref_response) }

  context "parsed crossref response" do
    let(:transformed_data) { metadata.build_work_actor_attributes }

    it "has title in format needed by hyrax actors" do
      transformed_data.keys&.each do |key|
        # expect(transformed_data[:title]).to eq attributes[:title]
        expect(transformed_data[key]).to eq attributes[key]
      end
    end
  end
end
