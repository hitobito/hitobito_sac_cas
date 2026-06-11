#  Copyright (c) 2026, Hitobito AG. this file is part of
#  hitobito_sac_cas and licensed under the affero general public license version 3
#  or later. see the copying file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ParticipationContactDatasController do
  let(:group) { event.groups.first }
  let(:entry) { assigns(:participation_contact_data) }

  before { sign_in(people(:admin)) }

  context "event" do
    let(:event) { Fabricate(:event) }

    context "GET#edit" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }

      it "renders form and and no aside" do
        get :edit, params: {
          group_id: event.groups.first.id,
          event_id: event.id,
          event_role: {type: Event::Role::Participant.sti_name}
        }
        expect(dom).not_to have_css "aside"
        expect(dom).to have_css "#content > form"
      end
    end
  end

  context "course" do
    let(:event) { events(:top_course) }

    context "GET#edit" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }

      it "renders form and aside" do
        get :edit, params: {
          group_id: group.id,
          event_id: event.id,
          event_role: {type: Event::Course::Role::Participant.sti_name}
        }
        expect(dom).to have_css "aside.card", count: 2
        expect(dom).to have_css "main > form"
        expect(dom).not_to have_css "#content > form"
      end
    end

    context "PATCH#update" do
      let(:person) { people(:admin) }

      it "stores attributes on person if valid" do
        event.update(required_contact_attrs: %w[phone_numbers])
        number = person.create_phone_number_mobile!(label: "mobile", number: "+41790000000")
        patch :update, params: {
          group_id: group.id,
          event_id: event.id,
          event_participation_contact_data: {
            gender: "m",
            email: person.email,
            first_name: person.first_name,
            birthday: "01.01.2002",
            street: "Musterplatz",
            housenumber: "23",
            zip_code: 1234,
            town: "Zürich",
            country: "CH",
            last_name: "NewName",
            phone_number_mobile_attributes: {
              id: number.id,
              number: "+41791111111"
            }
          },
          event_role: {
            type: "Event::Role::Participant"
          }
        }
        expect(entry).to have(0).errors,
          "Should not have errors, but has: #{entry.errors.full_messages.to_sentence}"
        expect(person.reload.last_name).to eq "NewName"
      end
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    context "GET#edit" do
      render_views
      let(:dom) { Capybara::Node::Simple.new(response.body) }

      it "renders form and aside" do
        get :edit, params: {
          group_id: group.id,
          event_id: event.id,
          event_role: {type: Event::Role::Participant.sti_name}
        }

        expect(dom).to have_css "aside.card", count: 2
        expect(dom).to have_css "main > form"
        expect(dom).not_to have_css "#content > form"
      end

      it "redirects to event if price_category for participation is not possible" do
        event.update!(regular_may_apply: false)

        get :edit, params: {
          group_id: group.id,
          event_id: event.id,
          event_role: {type: Event::Role::Participant.sti_name}
        }

        expect(response).to redirect_to(group_event_path(group, event))
        expect(flash[:alert]).to eq "Für diese Tour sind nur die folgenden Gruppen erlaubt: " \
          "Kosten SAC Sektionsmitglied, Kosten SAC-Mitglied (extern)"
      end
    end
  end
end
