# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Roles::ChangeZusatzsektionToFamilyLink do
  let(:person) { Fabricate(:person) }

  let(:stammsektion_class) { Group::SektionsMitglieder::Mitglied }
  let(:zusatzsektion_class) { Group::SektionsMitglieder::MitgliedZusatzsektion }
  let(:neuanmeldung_zusatzsektion_class) {
    Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion
  }
  let(:household_key) { SecureRandom.uuid }

  let(:household) { person.household }

  def create_role!(role_class, group, beitragskategorie: "family", **opts)
    Fabricate(
      role_class.sti_name,
      group:,
      beitragskategorie:,
      **opts.reverse_merge(
        person:,
        start_on: Time.current.beginning_of_year,
        end_on: Date.current.end_of_year
      )
    )
  end

  before do
    household.set_family_main_person!
    create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder))
    create_role!(zusatzsektion_class, groups(:matterhorn_mitglieder), beitragskategorie: :adult)
  end

  def stammsektion_role = person.sac_membership.stammsektion_role

  def zusatzsektion_role = person.sac_membership.zusatzsektion_roles.first

  context "#render" do
    context "for zusatzsektion role" do
      it "renders" do
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(true)
        expect(view).to receive(:params).and_return({group_id: zusatzsektion_role.group_id})

        expect(described_class.new(zusatzsektion_role, view).render)
          .to match(/Wechsel Familie/)
      end

      it "does not render for ended role" do
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(true)

        role = zusatzsektion_role
        role.end_on = Date.current.yesterday

        expect(described_class.new(role, view).render).to be_nil
      end

      it "does not render for non-Zusatzsektion role" do
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(true)

        role = Group::SektionsMitglieder::Ehrenmitglied.create!(
          person: person,
          group: groups(:bluemlisalp_mitglieder)
        )

        expect(described_class.new(role, view).render).to be_nil
      end

      it "does not render if cannot manage ChangeZusatzsektionToFamily" do
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(false)

        expect(described_class.new(zusatzsektion_role, view).render).to be_nil
      end

      it "does not render if role is family" do
        zusatzsektion_role.delete
        create_role!(zusatzsektion_class, groups(:matterhorn_mitglieder),
          beitragskategorie: :family)
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(true)

        expect(described_class.new(zusatzsektion_role, view).render).to be_nil
      end

      it "does not render if sac membership is adult" do
        stammsektion_role.delete
        create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder), beitragskategorie: :adult)
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(true)

        expect(described_class.new(zusatzsektion_role, view).render).to be_nil
      end

      it "does not render if person is not family main person" do
        other = Fabricate(:person, birthday: 23.years.ago)
        household.add(other).save!
        household.set_family_main_person!(other)
        expect(view).to receive(:can?)
          .with(:manage, Memberships::ChangeZusatzsektionToFamily)
          .and_return(true)

        expect(described_class.new(zusatzsektion_role, view).render).to be_nil
      end
    end
  end
end
