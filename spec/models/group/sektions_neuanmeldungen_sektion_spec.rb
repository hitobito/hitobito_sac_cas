# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"
require_relative "shared_examples_neuanmeldung"

describe Group::SektionsNeuanmeldungenSektion do
  describe Group::SektionsNeuanmeldungenSektion::Neuanmeldung do
    let(:person) { people(:admin) }
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

    it_behaves_like "validates Neuanmeldung timestamps"

    subject(:role) { Fabricate(described_class.sti_name, person: person, group: group, created_at: 10.days.ago) }

    it "#destroy hard destroys role even though it is old enough to soft destroy" do
      expect(role.send(:old_enough_to_soft_destroy?)).to eq true
      expect { role.destroy }.to change { Role.with_inactive.count }.by(-1)
    end
  end

  describe "self registration" do
    let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

    it "self registration role type cannot be changed" do
      expect(neuanmeldungen_sektion.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name)

      neuanmeldungen_sektion.update!(self_registration_role_type: Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name)

      expect(neuanmeldungen_sektion.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name)
    end

    it "self registration require adult consent is always enabled" do
      expect(neuanmeldungen_sektion.self_registration_require_adult_consent).to eq(true)

      neuanmeldungen_sektion.update!(self_registration_require_adult_consent: false)

      expect(neuanmeldungen_sektion.self_registration_require_adult_consent).to eq(true)
    end
  end
end
