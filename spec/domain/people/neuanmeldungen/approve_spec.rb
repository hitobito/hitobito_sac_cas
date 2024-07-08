# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Neuanmeldungen::Approve do
  let(:neuanmeldung_role_class) { Group::SektionsNeuanmeldungenSektion::Neuanmeldung }
  let(:neuanmeldung_approved_role_class) { Group::SektionsNeuanmeldungenNv::Neuanmeldung }

  let(:sektion) { groups(:bluemlisalp) }
  let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }

  def create_role(beitragskategorie)
    Fabricate(
      neuanmeldung_role_class.sti_name,
      group: neuanmeldungen_sektion,
      beitragskategorie: beitragskategorie,
      created_at: Time.zone.now.beginning_of_year,
      person: Fabricate(:person, birthday: 20.years.ago, sac_family_main_person: true)
    )
  end

  def expect_role(role, expected_role_class, expected_group)
    expect(role.person.roles).to have(1).item
    actual_role = role.person.roles.first
    expect(actual_role).to be_a expected_role_class
    expect(actual_role.group).to eq expected_group
    expect(actual_role.beitragskategorie).to eq role.beitragskategorie
  end

  it "replaces the neuanmeldungen_sektion roles with neuanmeldungen_nv roles" do
    neuanmeldungen = [:adult, :adult, :youth, :family].map { |cat| create_role(cat) }

    approver = described_class.new(
      group: neuanmeldungen_sektion,
      people_ids: [
        neuanmeldungen.first.person.id,
        neuanmeldungen.third.person.id,
        neuanmeldungen.fourth.person.id
      ]
    )

    expect { approver.call }
      .to change { neuanmeldung_role_class.count }.by(-3)
      .and change { neuanmeldung_approved_role_class.count }.by(3)

    expect_role(neuanmeldungen.first, neuanmeldung_approved_role_class, neuanmeldungen_nv)
    expect_role(neuanmeldungen.third, neuanmeldung_approved_role_class, neuanmeldungen_nv)
    expect_role(neuanmeldungen.fourth, neuanmeldung_approved_role_class, neuanmeldungen_nv)

    expect_role(neuanmeldungen.second, neuanmeldung_role_class, neuanmeldungen_sektion)
  end

  it "creates the SektionNeuanmeldungNv group if it does not exist" do
    neuanmeldungen_nv.destroy!
    neuanmeldung = create_role(:adult)

    described_class.new(group: neuanmeldungen_sektion, people_ids: [neuanmeldung.person.id]).call

    expect { neuanmeldung.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(neuanmeldung.person.roles).to have(1).item
    actual_role = neuanmeldung.person.roles.first
    expect(actual_role).to be_a neuanmeldung_approved_role_class
    expect(actual_role.group).to be_a Group::SektionsNeuanmeldungenNv
    expect(actual_role.group.parent_id).to eq sektion.id
    expect(actual_role.group.id).not_to eq neuanmeldungen_nv.id
  end
end
