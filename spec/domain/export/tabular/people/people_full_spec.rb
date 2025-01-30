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

  context "terminate_on" do
    before do
      person.roles_unscoped.destroy_all
      create_membership_role(2.years.ago, 1.years.ago)
    end

    it "has the correct label" do
      expect(subject.attribute_labels[:terminate_on]).to eq "Austrittsdatum"
    end

    it "has value from membership roles" do
      expect(row[:terminate_on]).to eq I18n.l(1.year.ago.to_date)
    end
  end

  context "termination_reason" do
    before do
      person.roles_unscoped.destroy_all
      create_membership_role(2.years.ago, 1.years.ago)
    end

    it "has the correct label" do
      expect(subject.attribute_labels[:termination_reason]).to eq "Austrittsgrund"
    end

    it "has value from membership roles" do
      expect(row[:termination_reason]).to eq "Umgezogen"
    end
  end

  def create_membership_role(start_on, end_on)
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym, group: groups(:bluemlisalp_mitglieder),
      person: people(:mitglied),
      start_on: start_on,
      end_on: end_on,
      termination_reason_id: TerminationReason.first.id)
  end
end
