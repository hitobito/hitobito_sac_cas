# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Wizards::Steps::Signup::Sektion::VariousFieldsHelper do
  it "return first period info text" do
    travel_to(Time.zone.local(2000, 2, 1)) do
      expect(entry_date_text).to eq("Bis 30. Juni ist der volle Beitrag des laufenden Jahres geschuldet. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
    end
  end

  it "should display second period info text" do
    travel_to(Time.zone.local(2000, 8, 1)) do
      expect(entry_date_text).to eq("Bei Eintritt zwischen dem 01. Juli und dem 30. September erhältst du 50% Rabatt auf den jährlichen Beitrag des laufenden Jahres. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
    end
  end

  it "should display third period info text" do
    travel_to(Time.zone.local(2000, 11, 1)) do
      expect(entry_date_text).to eq("Bei Eintritt ab dem 01. Oktober entfällt der jährliche Beitrag des laufenden Jahres. Es können noch weitere Gebühren anfallen, falls die Korrespondenzadresse im Ausland registriert ist.")
    end
  end
end
