# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Group::SektionsFunktionaere do
  [
    Group::SektionsFunktionaere::Praesidium,
    Group::SektionsFunktionaere::Mitgliederverwaltung,
    Group::SektionsFunktionaere::Finanzen
  ].each do |klass|
    it "#{klass.sti_name} has permission :download_member_statistics" do
      expect(klass.permissions).to include(:download_member_statistics)
    end
  end

  it "Group::SektionsFunktionaere::Administration has permission :layer_and_below_full" do
    expect(Group::SektionsFunktionaere::Administration.permissions)
      .to include(:layer_and_below_full)
  end

  it "Group::SektionsFunktionaere::AdministrationReadOnly has permission :layer_and_below_read" do
    expect(Group::SektionsFunktionaere::AdministrationReadOnly.permissions)
      .to include(:layer_and_below_read)
  end
end
