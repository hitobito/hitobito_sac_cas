# frozen_string_literal: true

# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require "spec_helper"

describe VariousAbility do
  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  context "as mitglied" do
    let(:role) {
      Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
        group: groups(:bluemlisalp_mitglieder))
    }

    it "may not index ChangelogEntry" do
      is_expected.not_to be_able_to(:index, ChangelogEntry)
    end
  end

  context "as andere" do
    let(:role) {
      Fabricate(Group::Geschaeftsstelle::Andere.name.to_sym, group: groups(:geschaeftsstelle))
    }

    it "may not view HitobitoLogEntry records" do
      is_expected.not_to be_able_to(:index, HitobitoLogEntry)
      is_expected.not_to be_able_to(:show, hitobito_log_entries(:info_mail))
    end
  end

  context "as mitarbeiter geschäftsstelle" do
    let(:role) {
      Fabricate(Group::Geschaeftsstelle::Mitarbeiter.name.to_sym, group: groups(:geschaeftsstelle))
    }

    it "may view HitobitoLogEntry records" do
      is_expected.to be_able_to(:index, HitobitoLogEntry)
      is_expected.to be_able_to(:show, hitobito_log_entries(:info_mail))
    end

    it "may index ChangelogEntry" do
      is_expected.to be_able_to(:index, ChangelogEntry)
    end
  end

  context "as mitarbeiter lesend geschäftsstelle" do
    let(:role) {
      Fabricate(Group::Geschaeftsstelle::MitarbeiterLesend.name.to_sym,
        group: groups(:geschaeftsstelle))
    }

    it "may view HitobitoLogEntry records" do
      is_expected.to be_able_to(:index, HitobitoLogEntry)
      is_expected.to be_able_to(:show, hitobito_log_entries(:info_mail))
    end

    it "may index ChangelogEntry" do
      is_expected.to be_able_to(:index, ChangelogEntry)
    end
  end
end
