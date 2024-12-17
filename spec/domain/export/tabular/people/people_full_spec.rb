# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::PeopleFull do
  let(:person) { people(:mitglied) }
  subject { described_class.new(Person.with_membership_years.where(id: person.id)) }

  let(:row) { subject.attributes.zip(subject.data_rows.first).to_h }

  context "membership_years" do
    it "has the correct label" do
      expect(subject.attribute_labels[:membership_years]).to eq "Anzahl Mitglieder-Jahre"
    end

    it "has value from person#membership_years" do
      expect(row[:membership_years]).to eq Person.with_membership_years.find(person.id).membership_years
    end
  end
end
