# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::Sektion::VariousFields do
  let(:wizard) { Wizards::Signup::SektionWizard.new(group: group) }
  subject(:fields) { described_class.new(wizard) }

  let(:group) { groups(:bluemlisalp_mitglieder) }

  before { SacMembershipConfig.update_all(valid_from: 2000) }

  context "current_date_entry_reductions text" do
    it "renders first period info text on first day of period" do
      travel_to(Time.zone.local(2000, 1, 1)) do
        expect(fields.current_date_entry_reductions).to eq("Bis 30.Juni ist der volle Beitrag des laufenden Jahres geschuldet. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
      end
    end

    it "renders first period info text on last day of first period" do
      travel_to(Time.zone.local(2000, 6, 30)) do
        expect(fields.current_date_entry_reductions).to eq("Bis 30.Juni ist der volle Beitrag des laufenden Jahres geschuldet. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
      end
    end

    it "renders third period info text on first day third of period" do
      travel_to(Time.zone.local(2000, 7, 1)) do
        expect(fields.current_date_entry_reductions).to eq("Bei Eintritt zwischen dem 01.Juli und dem 30.September erhältst du 50% Rabatt auf den jährlichen Beitrag des laufenden Jahres. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
      end
    end

    it "renders third period info text on last day of third period" do
      travel_to(Time.zone.local(2000, 9, 30)) do
        expect(fields.current_date_entry_reductions).to eq("Bei Eintritt zwischen dem 01.Juli und dem 30.September erhältst du 50% Rabatt auf den jährlichen Beitrag des laufenden Jahres. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
      end
    end

    it "renders third period info text on first day third of period" do
      travel_to(Time.zone.local(2000, 10, 1)) do
        expect(fields.current_date_entry_reductions).to eq("Bei Eintritt ab dem 01.Oktober entfällt der jährliche Beitrag des laufenden Jahres. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
      end
    end

    it "renders third period info text on last day of third period" do
      travel_to(Time.zone.local(2000, 12, 31)) do
        expect(fields.current_date_entry_reductions).to eq("Bei Eintritt ab dem 01.Oktober entfällt der jährliche Beitrag des laufenden Jahres. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
      end
    end
  end
end
