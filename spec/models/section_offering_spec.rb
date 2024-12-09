# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: section_offerings
#
#  id         :bigint           not null, primary key
#  title      :text(65535)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null

require "spec_helper"

describe SectionOffering do
  context "validations" do
    let(:section_offering) { described_class.new }

    it "validates title to be present" do
      expect(section_offering).not_to be_valid
      expect(section_offering.errors.full_messages).to eq ["Titel muss ausgefüllt werden"]
    end
  end

  context "destroy" do
    let(:section_offering) { described_class.create(title: "Offer 123") }

    before do
      Group::Sektion.first.section_offerings << section_offering
    end

    it "does not destroy when having one associated section" do
      expect { section_offering.destroy }.not_to change(described_class, :count)
      expect(section_offering.errors.full_messages).to include("Datensatz kann nicht gelöscht werden, da ein abhängiger Sektion-Datensatz existiert.")
    end
  
    it "does not destroy when having many associated sections" do
      Group::Sektion.second.section_offerings << section_offering
  
      expect { section_offering.destroy }.not_to change(described_class, :count)
      expect(section_offering.errors.full_messages).to include("Datensatz kann nicht gelöscht werden, da abhängige Sektionen existieren.")
    end
  end
end
