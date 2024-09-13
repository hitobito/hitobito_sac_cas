# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::SacRecipientHouseholds do
  let(:group) { groups(:bluemlisalp) }
  let(:list) { people(:mitglied, :familienmitglied, :abonnent) }

  subject(:tabular) { described_class.new(list, group) }

  its(:model_class) { is_expected.to eq Person }
  its(:row_class) { is_expected.to eq Export::Tabular::People::SacRecipientHouseholdRow }

  its(:attribute_labels) do
    is_expected.to eq(
      id: "Navision-Nr.",
      salutation: "Anrede",
      first_name: "Vorname",
      last_name: "Name",
      address_care_of: "zusätzliche Adresszeile",
      address: "Strasse",
      postbox: "Postfach",
      zip_code: "PLZ",
      town: "Ort",
      country: "Land",
      layer_navision_id: "Sektion",
      anzahl: "Anzahl",
      email: "E-Mail"
    )
  end
end
