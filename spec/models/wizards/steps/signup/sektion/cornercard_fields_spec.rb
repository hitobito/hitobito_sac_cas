# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::Sektion::CornercardFields do
  let(:wizard) { Wizards::Signup::SektionWizard.new(group: groups(:bluemlisalp_mitglieder)) }

  subject(:fields) { described_class.new(wizard) }

  describe "validations" do
    it "is valid when no checkbox is checked" do
      expect(fields).to be_valid
    end

    it "is valid when both checkboxes are checked" do
      fields.card_application = true
      fields.consent_given = true

      expect(fields).to be_valid
    end

    it "is invalid when only card_application is checked" do
      fields.card_application = true

      expect(fields).not_to be_valid
      expect(fields.errors.full_messages).to eq [
        "Bitte bestätige die Verarbeitung deiner Daten und die AGB, wenn du die Cornèrcard bestellen möchtest"
      ]
    end

    it "is invalid when only consent_given is checked" do
      fields.consent_given = true

      expect(fields).not_to be_valid
      expect(fields.errors.full_messages).to eq [
        "Bitte bestätige die Verarbeitung deiner Daten und die AGB, wenn du die Cornèrcard bestellen möchtest"
      ]
    end
  end

  describe "#ordered?" do
    it "is true only when both checkboxes are checked" do
      expect(fields).not_to be_ordered # with neither

      fields.card_application = true
      expect(fields).not_to be_ordered # with only card_application

      fields.consent_given = true
      expect(fields).to be_ordered # with both

      fields.card_application = false
      expect(fields).not_to be_ordered # with only consent_given
    end
  end
end
