# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::QuestionTemplateAbility do
  subject(:ability) { Ability.new(person) }

  let(:sektion) { groups(:bluemlisalp) }
  let(:template) { Event::QuestionTemplate.new(group: sektion) }
  let(:other_template) { Event::QuestionTemplate.new(group: groups(:matterhorn)) }

  context "as Tourenchef" do
    let(:person) do
      Fabricate(Group::SektionsTourenUndKurse::Tourenchef.sti_name,
        group: groups(:bluemlisalp_touren_und_kurse)).person
    end

    it { is_expected.to be_able_to(:manage, template) }
    it { is_expected.not_to be_able_to(:manage, other_template) }
  end

  context "as Touren-Kommission Mitglied" do
    let(:person) do
      Fabricate(Group::SektionsKommissionTouren::Mitglied.sti_name,
        group: groups(:bluemlisalp_kommission_touren)).person
    end

    it { is_expected.to be_able_to(:manage, template) }
    it { is_expected.not_to be_able_to(:manage, other_template) }
  end

  context "as Sektions-Administration" do
    let(:person) do
      Fabricate(Group::SektionsFunktionaere::Administration.sti_name,
        group: groups(:bluemlisalp_funktionaere)).person
    end

    it { is_expected.to be_able_to(:manage, template) }
  end

  context "as Freigabekomitee Pruefer" do
    let(:person) do
      Fabricate(Group::FreigabeKomitee::Pruefer.sti_name,
        group: groups(:bluemlisalp_freigabekomitee)).person
    end

    it { is_expected.not_to be_able_to(:manage, template) }
  end
end
