# frozen_string_literal: true

#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::AskFamilyMainPerson do
  let(:params) { {} }
  let(:wizard) { nil } # we don't need a wizard for the model specs
  let(:subject) { described_class.new(wizard, **params) }

  it "is always invalid" do
    is_expected.not_to be_valid
  end

  describe "#family_main_person_name" do
    let(:person) { people(:familienmitglied2) }
    let(:wizard) { Wizards::Base.new(current_step: 0) }

    before do
      allow(wizard).to receive(:person).and_return(person)
    end

    it "returns the family main person's name" do
      expect(subject.family_main_person_name).to eq(people(:familienmitglied).full_name)
    end
  end
end
