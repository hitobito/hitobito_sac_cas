# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"
require_relative "shared_examples_neuanmeldung"

describe Group::SektionsNeuanmeldungenNv do
  describe Group::SektionsNeuanmeldungenNv::Neuanmeldung do
    let(:person) { people(:admin) }
    let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

    it_behaves_like "validates Neuanmeldung timestamps"

    subject(:role) { Fabricate(described_class.sti_name, person: person, group: group, created_at: 10.days.ago) }

    it "#destroy hard destroys role even though it is old enough to archive" do
      expect(role.send(:old_enough_to_archive?)).to eq true
      expect { role.destroy }.to change { Role.with_deleted.count }.by(-1)
    end
  end

  describe "self registration" do
    let(:neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }

    it "self registration is disabled if neuanmeldungen sektion is present" do
      expect(neuanmeldungen_nv.self_registration_role_type).to be_nil

      neuanmeldungen_nv.update!(self_registration_role_type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name)

      expect(neuanmeldungen_nv.self_registration_role_type).to be_nil
    end

    it "self registration role type cannot be changed" do
      groups(:bluemlisalp_neuanmeldungen_sektion).really_destroy!
      expect(neuanmeldungen_nv.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name)

      neuanmeldungen_nv.update!(self_registration_role_type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name)

      expect(neuanmeldungen_nv.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name)
    end

    it "self registration require adult consent is always enabled" do
      expect(neuanmeldungen_nv.self_registration_require_adult_consent).to eq(true)

      neuanmeldungen_nv.update!(self_registration_require_adult_consent: false)

      expect(neuanmeldungen_nv.self_registration_require_adult_consent).to eq(true)
    end
  end
end
