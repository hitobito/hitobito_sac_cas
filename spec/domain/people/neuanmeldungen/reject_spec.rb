# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Neuanmeldungen::Reject do
  include ActiveJob::TestHelper

  let(:neuanmeldung_role_class) { Group::SektionsNeuanmeldungenSektion::Neuanmeldung }

  let(:sektion) { groups(:bluemlisalp) }
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:neuanmeldung) { create_role(:adult) }
  let(:person) do
    Fabricate(Group::AboMagazin::Abonnent.sti_name, group: groups(:abo_die_alpen), created_at: 1.year.ago, person: neuanmeldung.person)
    neuanmeldung.person.reload
  end

  def create_role(beitragskategorie)
    Fabricate(
      neuanmeldung_role_class.sti_name,
      group: group,
      beitragskategorie: beitragskategorie,
      created_at: 1.year.ago,
      person: Fabricate(:person, birthday: 20.years.ago, sac_family_main_person: true)
    )
  end

  def rejector(people_ids = [person.id], **opts)
    described_class.new(group: group, people_ids: people_ids, **opts)
  end

  it "deletes the Neuanmeldung roles" do
    neuanmeldung_einzel = create_role(:adult)
    neuanmeldung_familie = create_role(:family)
    neuanmeldung_jugend = create_role(:youth)

    subject = rejector([neuanmeldung_einzel.person.id, neuanmeldung_jugend.person.id])

    expect { subject.call }.to change { neuanmeldung_role_class.count }.by(-2)

    expect(neuanmeldung_einzel.person.roles).to be_empty
    expect(neuanmeldung_jugend.person.roles).to be_empty
    expect(neuanmeldung_familie.person.reload.roles).to have(1).item
  end

  it "deletes rejected Roles, if it has other roles" do
    rejector.call
    expect(person.reload.roles).not_to include(neuanmeldung)

    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
      created_at: 1.year.ago, person: neuanmeldung.person)
    neuanmeldung_zusatzsektion = Fabricate(Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name,
      group: group, created_at: 1.month.ago, person: neuanmeldung.person)

    rejector.call
    expect(person.reload.roles).not_to include(neuanmeldung_zusatzsektion)
  end

  it "deletes rejected Roles, if it has other deleted roles" do
    person.roles.each { |role| role.update!(deleted_at: 1.day.ago) if role.type != neuanmeldung_role_class.sti_name }

    rejector.call
    expect(person.reload.roles).not_to include(neuanmeldung)
  end

  it "deletes the Person, if it has no other roles" do
    person.roles.each { |role| role.really_destroy! if role.type != neuanmeldung_role_class.sti_name }

    rejector.call
    expect { Person.find(person.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "adds a Person#note if a note was provided" do
    expect { rejector(note: "my note").call }
      .to change { person.reload.notes.count }.by(1)

    note = person.notes.last
    expect(note.text).to eq "my note"
    expect(note.author).to eq nil
  end

  it "adds a Person#note with author if an author was provided" do
    expect { rejector(note: "my note", author: people(:mitglied)).call }
      .to change { person.reload.notes.count }.by(1)

    note = person.notes.last
    expect(note.text).to eq "my note"
    expect(note.author).to eq people(:mitglied)
  end

  it "send an email to the person" do
    expect { rejector.call }
      .to have_enqueued_mail(People::NeuanmeldungenMailer, :reject).exactly(:once) # .with
  end

  it "doesnt send email if not main person" do
    person.update!(sac_family_main_person: false)
    expect { rejector.call }.not_to have_enqueued_mail(People::NeuanmeldungenMailer)
  end
end
