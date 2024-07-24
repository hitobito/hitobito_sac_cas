# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "../shared_examples_mitglied_dependant_destroy"

describe Group::SektionsTourenUndKurse::Tourenleiter do
  it_behaves_like "Mitglied dependant destroy" do
    let(:sektion) { groups(:bluemlisalp) }
    let(:funktionaere) { Group::SektionsFunktionaere.find_by(parent: sektion) }
    let(:tourenkommission) { Group::SektionsTourenUndKurse.find_or_create_by(parent: funktionaere) }
    let(:person) { Fabricate(:qualification).person }
    let(:role) { described_class.new(group: tourenkommission, person: person) }
  end
end
