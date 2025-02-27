# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe EventKindReadables do
  let!(:section_may_create_kinds) { event_kinds + [Fabricate(:sac_event_kind, section_may_create: true)] }
  let!(:section_may_not_create_kinds) { [Fabricate(:sac_event_kind, section_may_create: false)] }
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:andere) do
    Fabricate(Group::Geschaeftsstelle::Andere.sti_name.to_sym,
      group: groups(:geschaeftsstelle)).person
  end
  let(:mitgliederverwaltung_sektion) do
    Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
      group: groups(:bluemlisalp_funktionaere)).person
  end

  context "index" do
    def accessible_by(user)
      Event::Kind.accessible_by(described_class.new(user))
    end

    it "returns everything regardless of section_may_create for admin" do
      expect(accessible_by(admin)).to match_array section_may_create_kinds + section_may_not_create_kinds
    end

    it "returns only section_may_create=true kinds for andere" do
      expect(accessible_by(andere)).to match_array section_may_create_kinds
    end

    it "returns only section_may_create=true kinds for mitglied" do
      expect(accessible_by(mitglied)).to match_array section_may_create_kinds
    end

    it "returns only section_may_create=true kinds for mitgliederverwaltung" do
      expect(accessible_by(mitgliederverwaltung_sektion)).to match_array section_may_create_kinds
    end
  end
end
