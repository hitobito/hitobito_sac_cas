# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/tours/approvals", js: true do
  let(:user) { people(:tourenchef) }
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }

  let(:user) { people(:admin) }

  before { sign_in(user) }

  before do
    create_pruefer(event_approval_kinds(:professional, :security))
  end

  def create_pruefer(approval_kinds)
    Group::FreigabeKomitee::Pruefer.create!(group: komitee, person: user, approval_kinds: approval_kinds)
  end

  def create_approval(kind, approved, freigabe_komitee = komitee)
    event.approvals.create!(
      approval_kind: event_approval_kinds(kind),
      approved: approved,
      freigabe_komitee: freigabe_komitee,
      creator: people(:admin)
    )
  end

  it "edits and submits approval" do
    visit group_event_path(group, event)

    click_link "Freigabe"

    expect(page).to have_selector("h1", text: "Freigabe")

    expect(page).to have_checked_field(count: 2)

    fill_in "Interne Bemerkungen", with: "Gut so"
    expect(page).to have_selector("button", text: "Freigeben")
    expect(page).to have_selector("button", text: "Ablehnen")

    click_button "Freigeben"

    expect(page).to have_selector("h1", text: "Bundstock")
    expect(page).to have_selector(".alert-success", text: "Deine Freigabe wurde gespeichert.")
    expect(page).to have_selector(".alert-info", text: "Gut so")

    expect(event.approvals.count).to eq(2)
  end

  it "edits and submits rejection" do
    visit group_event_path(group, event)

    click_link "Freigabe"

    expect(page).to have_selector("h1", text: "Freigabe")

    expect(page).to have_checked_field(count: 2)
    uncheck("Sicherheit")
    fill_in "Interne Bemerkungen", with: "Nochmals"

    expect(page).to have_selector("button", text: "Freigeben")
    expect(page).to have_selector("button", text: "Ablehnen")

    click_button "Ablehnen"

    expect(page).to have_selector("h1", text: "Bundstock")
    expect(page).to have_selector(".alert-success", text: "Deine Ablehnung wurde gespeichert")
    expect(page).to have_selector(".alert-info", text: "Nochmals")

    expect(event.reload.state).to eq("draft")
    expect(event.approvals.count).to eq(1)
    expect(event.approvals.first.approved).to be(false)
  end

  it "un-/checks dependent checkboxes per komitee" do
    other_komitee = Group::FreigabeKomitee.create!(name: "Komitee 2",
      parent: groups(:bluemlisalp_touren_und_kurse))
    event_approval_commission_responsibilities(:bluemlisalp_wandern_familien).update!(freigabe_komitee: other_komitee)
    Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
      approval_kinds: [event_approval_kinds(:professional)])
    Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
      approval_kinds: [event_approval_kinds(:security)])
    Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
      approval_kinds: [event_approval_kinds(:editorial)])

    visit group_event_path(group, event)

    click_link "Freigabe"

    expect(page).to have_selector("h1", text: "Freigabe")

    expect(page).to have_content(komitee.to_s)
    expect(page).to have_content(other_komitee.to_s)

    expect(page).to have_checked_field(count: 5)

    within("form > .row:nth-of-type(1)") do
      expect(page).to have_checked_field(count: 2)
      uncheck("Fachlich")
      expect(page).to have_unchecked_field(count: 2)
    end

    within("form > .row:nth-of-type(2)") do
      expect(page).to have_checked_field(count: 3)
      uncheck("Fachlich")
      expect(page).to have_unchecked_field(count: 3)

      check("Sicherheit")
      expect(page).to have_checked_field(count: 2)
      expect(page).to have_checked_field("Fachlich")
    end

    within("form > .row:nth-of-type(1)") do
      expect(page).to have_unchecked_field(count: 2)

      check("Fachlich")
      expect(page).to have_checked_field(count: 1)
      expect(page).to have_unchecked_field("Sicherheit")
    end

    within("form > .row:nth-of-type(2)") do
      expect(page).to have_checked_field(count: 2)
      check("Redaktionell")
      expect(page).to have_checked_field(count: 3)

      uncheck("Sicherheit")
      expect(page).to have_checked_field("Fachlich")
      expect(page).to have_unchecked_field("Redaktionell")
    end
  end
end
