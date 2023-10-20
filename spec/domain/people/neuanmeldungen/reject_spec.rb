# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::Neuanmeldungen::Reject do
  NEUANMELDUNG_ROLE_CLASS = Group::SektionsNeuanmeldungenSektion::Neuanmeldung

  let(:sektion) { groups(:bluemlisalp) }
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:neuanmeldung) { create_role(:einzel) }

  def create_role(beitragskategorie)
    Fabricate(
      NEUANMELDUNG_ROLE_CLASS.sti_name,
      group: group,
      beitragskategorie: beitragskategorie,
      created_at: 1.year.ago,
      person: Fabricate(:person, birthday: 20.years.ago)
    )
  end

  def rejector(people_ids = [neuanmeldung.person.id], **opts)
    described_class.new(group: group, people_ids: people_ids, **opts)
  end

  it 'deletes the Neuanmeldung roles' do
    neuanmeldung_einzel = create_role(:einzel)
    neuanmeldung_familie = create_role(:familie)
    neuanmeldung_jugend = create_role(:jugend)

    subject = rejector([neuanmeldung_einzel.person.id, neuanmeldung_jugend.person.id])

    expect { subject.call }.to change { NEUANMELDUNG_ROLE_CLASS.count }.by(-2)

    expect(neuanmeldung_einzel.person.roles).to be_empty
    expect(neuanmeldung_einzel.person.roles.with_deleted).to have(1).item

    expect(neuanmeldung_jugend.person.roles).to be_empty
    expect(neuanmeldung_jugend.person.roles.with_deleted).to have(1).item

    expect(neuanmeldung_familie.person.roles).to have(1).item
    expect(neuanmeldung_familie.person.roles.with_deleted).to have(1).item
  end

  it 'disables the Person login' do
    neuanmeldung.person.update!(
      email: 'dummy@example.com',
      password: 'my-password1',
      password_confirmation: 'my-password1'
    )
    expect(neuanmeldung.person.login_status).to eq :login

    expect do
      described_class.new(group: group, people_ids: [neuanmeldung.person.id]).call
    end.to change { neuanmeldung.person.reload.login_status }.to(:no_login)
  end

  it 'adds a Person#note if a note was provided' do
    expect { rejector(note: 'my note').call }.
      to change { neuanmeldung.person.reload.notes.count }.by(1)

    note = neuanmeldung.person.notes.last
    expect(note.text).to eq 'my note'
    expect(note.author).to eq nil
  end

  it 'adds a Person#note with author if an author was provided' do
    expect { rejector(note: 'my note', author: people(:mitglied)).call }.
      to change { neuanmeldung.person.reload.notes.count }.by(1)

    note = neuanmeldung.person.notes.last
    expect(note.text).to eq 'my note'
    expect(note.author).to eq people(:mitglied)
  end
end
