# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe GroupAbility do
  subject { Ability.new(person) }

  describe "index_question_templates" do
    let(:sektion) { groups(:bluemlisalp) }
    let(:ortsgruppe) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

    {
      Group::SektionsTourenUndKurse::Tourenchef => :bluemlisalp_touren_und_kurse,
      Group::SektionsKommissionTouren::Mitglied => :bluemlisalp_kommission_touren,
      Group::SektionsFunktionaere::Administration => :bluemlisalp_funktionaere
    }.each do |role_type, group_name|
      context "as #{role_type.sti_name}" do
        let(:person) { Fabricate(role_type.sti_name, group: groups(group_name)).person }

        it { is_expected.to be_able_to(:index_question_templates, sektion) }
        it { is_expected.not_to be_able_to(:index_question_templates, ortsgruppe) }
      end
    end

    context "as Tourenchef of ortsgruppe" do
      let(:person) do
        Fabricate(Group::SektionsTourenUndKurse::Tourenchef.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_touren_und_kurse)).person
      end

      it { is_expected.to be_able_to(:index_question_templates, ortsgruppe) }
      it { is_expected.not_to be_able_to(:index_question_templates, sektion) }
    end

    context "as Freigabekomitee Pruefer" do
      let(:person) do
        Fabricate(Group::FreigabeKomitee::Pruefer.sti_name,
          group: groups(:bluemlisalp_freigabekomitee)).person
      end

      it { is_expected.not_to be_able_to(:index_question_templates, sektion) }
    end
  end

  describe "create_yearly_membership_invoice" do
    context "as admin" do
      let(:person) { people(:admin) }

      it { is_expected.to be_able_to(:create_yearly_membership_invoice, groups(:bluemlisalp)) }
    end

    context "as mitglied" do
      let(:person) { people(:mitglied) }

      it { is_expected.not_to be_able_to(:create_yearly_membership_invoice, groups(:bluemlisalp)) }
    end

    describe "download_statistics" do
      context "as admin" do
        let(:person) { people(:admin) }

        it { is_expected.to be_able_to(:download_statistics, groups(:root)) }

        it { is_expected.not_to be_able_to(:download_statistics, groups(:bluemlisalp)) }
      end
    end
  end

  describe "restricted groups" do
    let(:funktionaere) { groups(:bluemlisalp_funktionaere) }

    context "as sac admin" do
      let(:person) { people(:admin) }

      it { is_expected.to be_able_to(:create, Group::SektionsClubhuetten.new(parent: funktionaere)) }
      it { is_expected.to be_able_to(:destroy, groups(:bluemlisalp_mitglieder)) }
    end

    context "as sektions admin" do
      let(:person) do
        Fabricate(Group::SektionsFunktionaere::Administration.name.to_sym,
          group: funktionaere).person
      end

      it do
        is_expected.not_to be_able_to(:create,
          Group::SektionsClubhuetten.new(parent: funktionaere))
      end
      it { is_expected.not_to be_able_to(:destroy, groups(:bluemlisalp_mitglieder)) }
    end

    context "as schreibrecht" do
      let(:huetten) { Group::Sektionshuetten.create!(parent: funktionaere) }
      let(:person) do
        Fabricate(Group::SektionsFunktionaere::Schreibrecht.name.to_sym, group: funktionaere).person
      end

      it { is_expected.not_to be_able_to(:create, Group::Sektionshuette.new(parent: huetten)) }
      it { is_expected.not_to be_able_to(:destroy, Group::Sektionshuette.create!(name: "Testhütte", parent: huetten)) }
    end
  end
end
