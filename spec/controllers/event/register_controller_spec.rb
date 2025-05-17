#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::RegisterController do
  include ActiveJob::TestHelper

  let(:event) do
    events(:top_event).tap do |e|
      e.update_column(:external_applications, true)
    end
  end
  let(:group) { event.groups.first }

  let(:attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      street: "Musterplatz",
      housenumber: "23",
      email: "max.muster@example.com",
      zip_code: "8000",
      town: "Zürich",
      country: "CH",
      birthday: "01.01.1980",
      phone_number_mobile_attributes: {
        number: "+41 79 123 45 56"
      }
    }.with_indifferent_access
  }

  describe "PUT register" do
    context "with valid data" do
      it "creates person and sends password reset instructions" do
        event.update!(required_contact_attrs: [])

        expect(Devise::Mailer).to receive(:reset_password_instructions).and_call_original

        expect do
          put :register, params: {group_id: group.id, id: event.id, event_participation_contact_data: attrs}
        end.to change { Person.count }.by(1)
          .and change { Group::AboBasicLogin::BasicLogin.count }.by(1)

        person = Person.find_by(email: "max.muster@example.com")

        expect(person.roles.size).to eq(1)
        expect(person.roles.first.type).to eq(Group::AboBasicLogin::BasicLogin.sti_name)
        is_expected.to redirect_to(new_group_event_participation_path(group, event))
        expect(flash[:notice]).to include "Deine persönlichen Daten wurden aufgenommen. Bitte ergänze nun noch die Angaben"
      end
    end

    context "without any phone number" do
      it "does not create person" do
        attrs.delete(:phone_number_mobile_attributes)

        expect do
          put :register, params: {group_id: group.id, id: event.id, event_participation_contact_data: attrs}
        end.not_to change { Person.count }
      end
    end
  end
end
