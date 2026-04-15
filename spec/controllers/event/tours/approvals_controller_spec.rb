# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tours::ApprovalsController do
  let(:user) { people(:tourenchef) }
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }

  subject(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  before do
    Group::SektionsTourenUndKurse::TourenchefSommer.create!(
      group: groups(:bluemlisalp_touren_und_kurse),
      person: user,
      start_on: "2015-01-01"
    )
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

  before { sign_in(user) }

  describe "GET#edit" do
    let!(:other_komitee) do
      Group::FreigabeKomitee.create!(name: "Komitee 2",
        parent: groups(:bluemlisalp_touren_und_kurse)).tap do |other|
        event_approval_commission_responsibilities(:bluemlisalp_wandern_familien)
          .update!(freigabe_komitee: other)
      end
    end

    def checkbox_id(komitee_index, kind_index)
      "event_tour_approval_form_komitee_approvals_attributes_#{komitee_index}" \
      "_approval_kind_approvals_attributes_#{kind_index}_checked"
    end

    context "as pruefer" do
      before do
        create_pruefer(event_approval_kinds(:professional, :security))
        Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
          approval_kinds: [event_approval_kinds(:professional)])
        Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
          approval_kinds: [event_approval_kinds(:editorial)])
      end

      it "renders all allowed checkboxes" do
        get :edit, params: {group_id: group.id, event_id: event.id}

        expect(response).to have_http_status(:success)

        expect(dom).to have_content(komitee.to_s)
        expect(dom).to have_content(other_komitee.to_s)

        expect(dom).to have_content("Fachlich", count: 2)

        expect(dom).to have_checked_field(count: 3)
        expect(dom).to have_checked_field(checkbox_id(0, 0))
        expect(dom).to have_checked_field(checkbox_id(0, 1))
        expect(dom).not_to have_checked_field(checkbox_id(0, 2))

        expect(dom).to have_checked_field(checkbox_id(1, 0))
        expect(dom).not_to have_checked_field(checkbox_id(1, 1))
        expect(dom).not_to have_checked_field(checkbox_id(1, 2))

        expect(dom).to have_button("Freigeben")
        expect(dom).to have_button("Ablehnen")
      end

      it "renders rejected checkboxes" do
        create_approval(:professional, false)
        create_approval(:security, false)
        create_approval(:professional, true, other_komitee)
        create_approval(:security, true, other_komitee)

        get :edit, params: {group_id: group.id, event_id: event.id}

        expect(response).to have_http_status(:success)

        expect(dom).to have_content(komitee.to_s)
        expect(dom).to have_content(other_komitee.to_s)

        expect(dom).to have_content("Fachlich", count: 2)
        expect(dom).to have_content("Abgelehnt von Anna Admin am", count: 2)
        expect(dom).to have_content("Freigegeben von Anna Admin am", count: 2)

        expect(dom).to have_checked_field(count: 3)
        expect(dom).to have_checked_field(checkbox_id(0, 0))
        expect(dom).to have_checked_field(checkbox_id(0, 1))
        expect(dom).not_to have_checked_field(checkbox_id(0, 2))

        expect(dom).not_to have_checked_field(checkbox_id(1, 0))
        expect(dom).not_to have_checked_field(checkbox_id(1, 1))
        expect(dom).to have_checked_field(checkbox_id(1, 2))

        expect(dom).to have_button("Freigeben")
        expect(dom).to have_button("Ablehnen")
      end

      it "renders only info for drafts" do
        event.update!(state: :draft)

        get :edit, params: {group_id: group.id, event_id: event.id}

        expect(response).to have_http_status(:success)

        expect(dom).to have_content(komitee.to_s)
        expect(dom).to have_content(other_komitee.to_s)

        expect(dom).to have_content("Fachlich", count: 2)
        expect(dom).to have_content("–", count: 6)
        expect(dom).not_to have_checked_field

        expect(dom).to have_button("Speichern")
      end

      it "renders self approval infos" do
        event.update!(state: :approved)
        event.approvals.create!(approved: true, creator: people(:admin))

        get :edit, params: {group_id: group.id, event_id: event.id}

        expect(response).to have_http_status(:success)

        expect(dom).not_to have_content(komitee.to_s)
        expect(dom).not_to have_content("Fachlich")
        expect(dom).to have_content("Selbst freigegeben von Anna Admin am")

        expect(dom).to have_button("Speichern")
      end
    end

    context "as tourenchef" do
      it "renders only infos" do
        create_approval(:professional, false)
        create_approval(:security, false)
        create_approval(:professional, true, other_komitee)
        create_approval(:security, true, other_komitee)

        get :edit, params: {group_id: group.id, event_id: event.id}

        expect(response).to have_http_status(:success)

        expect(dom).to have_content(komitee.to_s)
        expect(dom).to have_content(other_komitee.to_s)

        expect(dom).to have_content("Fachlich", count: 2)
        expect(dom).to have_content("Abgelehnt von Anna Admin am", count: 2)
        expect(dom).to have_content("Freigegeben von Anna Admin am", count: 2)

        expect(dom).not_to have_checked_field

        expect(dom).to have_button("Speichern")
      end
    end
  end

  describe "PUT#update" do
    context "as pruefer" do
      before do
        create_pruefer(event_approval_kinds(:professional, :security))
      end

      it "approves all allowed checkboxes" do
        put :update, params: {
          group_id: group.id,
          event_id: event.id,
          button: "approve",
          event_tour_approval_form: {
            internal_comment: "Weiter so",
            komitee_approvals_attributes: {
              "0" => {
                freigabe_komitee_id: komitee.id,
                approval_kind_approvals_attributes: {
                  "0" => {approval_kind_id: event_approval_kinds(:professional).id, checked: "1"},
                  "1" => {approval_kind_id: event_approval_kinds(:security).id, checked: "1"},
                  "2" => {approval_kind_id: event_approval_kinds(:editorial).id, checked: "1"}
                }
              }
            }
          }
        }

        expect(response).to redirect_to(group_event_path(group, event))
        expect(flash[:notice]).to eq("Deine Freigabe wurde gespeichert.")

        expect(event.reload.internal_comment).to eq("Weiter so")
        expect(event.state).to eq("review")
        expect(event.approvals.count).to eq(2)
      end

      it "rejects all selected checkboxes" do
        put :update, params: {
          group_id: group.id,
          event_id: event.id,
          button: "reject",
          event_tour_approval_form: {
            internal_comment: "Weiter so",
            komitee_approvals_attributes: {
              "0" => {
                freigabe_komitee_id: komitee.id,
                approval_kind_approvals_attributes: {
                  "0" => {approval_kind_id: event_approval_kinds(:professional).id, checked: "1"},
                  "1" => {approval_kind_id: event_approval_kinds(:security).id, checked: "0"},
                  "2" => {approval_kind_id: event_approval_kinds(:editorial).id, checked: "0"}
                }
              }
            }
          }
        }

        expect(response).to redirect_to(group_event_path(group, event))
        expect(flash[:notice]).to eq(
          "Deine Ablehnung wurde gespeichert und die Tour zurück in den Status <i>Entwurf</i> gesetzt."
        )

        expect(event.reload.internal_comment).to eq("Weiter so")
        expect(event.state).to eq("draft")
        expect(event.approvals.count).to eq(1)
      end
    end

    context "as tourenchef" do
      it "saves only internal comment" do
        put :update, params: {
          group_id: group.id,
          event_id: event.id,
          event_tour_approval_form: {
            internal_comment: "Weiter so",
            komitee_approvals_attributes: {
              "0" => {
                freigabe_komitee_id: komitee.id,
                approval_kind_approvals_attributes: {
                  "0" => {approval_kind_id: event_approval_kinds(:professional).id, checked: true},
                  "1" => {approval_kind_id: event_approval_kinds(:security).id, checked: true},
                  "2" => {approval_kind_id: event_approval_kinds(:editorial).id, checked: true}
                }
              }
            }
          }
        }

        expect(response).to redirect_to(group_event_path(group, event))
        expect(flash[:notice]).to eq("Deine Bemerkung wurde gespeichert.")

        expect(event.reload.internal_comment).to eq("Weiter so")
        expect(event.state).to eq("review")
        expect(event.approvals.count).to eq(0)
      end
    end
  end
end
