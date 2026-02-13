# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ApprovalCommissionResponsibilitiesController do
  before { sign_in(current_user) }

  let(:current_user) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }
  let(:another_freigabe_komitee) {
    Group::FreigabeKomitee.create!(name: "Freigabekomitee", parent: groups(:bluemlisalp_touren_und_kurse))
  }

  render_views

  it "GET#edit renders dropdown for each approval_commission_responsibility" do
    get :edit, params: {group_id: group.id}
    expect(dom).to have_css "select", count: 36
  end

  it "PATCH#update can update multiple entries" do
    patch :update, params: {
      group_id: group.id,
      event_approval_commission_responsibility_form: {
        event_approval_commission_responsibilities_attributes: {
          "1": {
            id: event_approval_commission_responsibilities(:bluemlisalp_wandern_kinder_subito).id,
            target_group_id: event_target_groups(:kinder),
            discipline_id: event_disciplines(:wandern),
            freigabe_komitee_id: another_freigabe_komitee,
            subito: true
          },
          "2": {
            id: event_approval_commission_responsibilities(:bluemlisalp_wandern_kinder).id,
            target_group_id: event_target_groups(:kinder),
            discipline_id: event_disciplines(:wandern),
            freigabe_komitee_id: another_freigabe_komitee,
            subito: false
          }
        }
      }
    }
    expect(response).to redirect_to(tour_group_events_path(group))

    responsibility_1 = event_approval_commission_responsibilities(:bluemlisalp_wandern_kinder).reload
    responsibility_2 = event_approval_commission_responsibilities(:bluemlisalp_wandern_kinder_subito).reload

    expect(responsibility_1.freigabe_komitee).to eq another_freigabe_komitee
    expect(responsibility_2.freigabe_komitee).to eq another_freigabe_komitee
  end

  it "PATCH#update creates new records when combination doesn't exist" do
    group.event_approval_commission_responsibilities.destroy_all

    expect do
      patch :update, params: {
        group_id: group.id,
        event_approval_commission_responsibility_form: {
          event_approval_commission_responsibilities_attributes: {
            "1": {
              target_group_id: event_target_groups(:kinder),
              discipline_id: event_disciplines(:wandern),
              freigabe_komitee_id: another_freigabe_komitee,
              subito: true
            },
            "2": {
              target_group_id: event_target_groups(:kinder),
              discipline_id: event_disciplines(:wandern),
              freigabe_komitee_id: another_freigabe_komitee,
              subito: false
            }
          }
        }
      }
    end.to change { group.event_approval_commission_responsibilities.count }.by(2)
  end
end
