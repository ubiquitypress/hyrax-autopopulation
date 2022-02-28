# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hyrax::Autopopulation::RecordPersistence do
  context "clean strings" do
    let(:bad_string_with_escape_characters) { "\"10.1629/uksg.236\", \"10.1371/journal.pone.0261098\", \"10.1087/20120404\", \"10.5334/joc.210\", \"10.5334/joc.209\"" }
    let(:cleaned_without_escape_charaters) { ["10.1629/uksg.236", "10.1371/journal.pone.0261098", "10.1087/20120404", "10.5334/joc.210", "10.5334/joc.209"] }

    let(:string_with_new_line_and_space) { "10.1038/srep15737 \n 10.1038/nature12373 , 10.1016/j.crvasa.2015.05.008 10.1111/1559-8918.2019.01273" }
    let(:cleaned_string_with_new_line_and_space) { ["10.1038/srep15737", "10.1038/nature12373", "10.1016/j.crvasa.2015.05.008", "10.1111/1559-8918.2019.01273"] }
    let(:data) do
      { "settings" => { "doi_list" => bad_string_with_escape_characters } }
    end

    let(:account) { instance_double(Account, cname: "repo") }
    let(:subject) { described_class.new(data: data, account: account) }

    before do
      allow(AccountElevator).to receive(:switch!).and_return(true)
    end
    it "can remove escape characters" do
      expect(subject.send(:split_string, "doi_list")).to eq cleaned_without_escape_charaters
    end

    it "can split on new line and space" do
      data["settings"]["doi_list"] = string_with_new_line_and_space
      expect(subject.send(:split_string, "doi_list")).to eq cleaned_string_with_new_line_and_space
    end
  end
end
