# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe PeopleController do
  render_views

  let(:body) { Capybara::Node::Simple.new(response.body) }
  let(:admin) { people(:admin) }

  let(:people_table) { body.all("#main table tbody tr") }
  let(:pagination_info) { body.find(".pagination-info").text.strip }
  let(:members_filter) { body.find(".toolbar-pills > ul > li:nth-child(1)") }
  let(:custom_filter) { body.find(".toolbar-pills > ul > li.dropdown") }

  before { sign_in(admin) }

  context "GET#index" do
    it "accepts filter params and lists neuanmeldungen" do
      person1 = Fabricate(:person, birthday: Time.zone.today - 42.years)
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s,
        group: groups(:bluemlisalp_neuanmeldungen_nv),
        person: person1)
      person2 = Fabricate(:person, birthday: Time.zone.today - 42.years)
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.to_s,
        group: groups(:bluemlisalp_neuanmeldungen_sektion),
        person: person2)
      roles = {role_type_ids: Group::SektionsNeuanmeldungenNv::Neuanmeldung.type_id}
      get :index, params: {group_id: groups(:root).id, filters: {role: roles}, range: "deep"}

      expect(members_filter.text).to eq "Neuanmeldungen (1)"
      expect(members_filter[:class]).not_to eq "active"

      expect(pagination_info).to eq "1 Person angezeigt."
      expect(people_table).to have(1).item
    end

    context "with format=csv and param recipients=true" do
      it "calls ... with ..." do
        expect do
          get :index, params: {
            format: :csv,
            group_id: groups(:bluemlisalp_mitglieder),
            recipients: true
          }
          expect(response).to be_redirect
        end.to change { Delayed::Job.count }.by(1)

        job = Delayed::Job.last.payload_object
        expect(job).to be_a(Export::PeopleExportJob)

        expect(Export::Tabular::People::SacRecipients)
          .to receive(:export)
        job.perform
      end
    end
  end

  context "GET#show" do
    context "household_key" do
      def make_person(beitragskategorie, role_class: Group::SektionsMitglieder::Mitglied,
        group: groups(:bluemlisalp_mitglieder))
        Fabricate(
          :person,
          birthday: Time.zone.today - 33.years,
          household_key: "household-42",
          sac_family_main_person: true
        ).tap do |person|
          Fabricate(role_class.to_s,
            group: group,
            person: person,
            beitragskategorie: beitragskategorie)
        end
      end

      def expect_household_key(person, visible:)
        matcher = visible ? :have_selector : :have_no_selector

        get :show, params: {id: person.id, group_id: groups(:root).id}

        expect(body).to send(matcher, "dt", text: "Familien ID")
        expect(body).to send(matcher, "dd", text: person.household_key)
      end

      it "is shown for person with any role having beitragskategorie=family" do
        person = make_person(:family)
        expect_household_key(person, visible: true)
      end

      [:adult, :youth].each do |beitragskategorie|
        it "is not shown for person with any role having beitragskategorie=#{beitragskategorie}" do
          person = make_person(beitragskategorie)
          expect_household_key(person, visible: false)
        end
      end

      it "is not shown for person with non-mitglied role" do
        person = make_person(nil, role_class: Group::Geschaeftsstelle::Admin,
          group: groups(:geschaeftsstelle))
        expect_household_key(person, visible: false)
      end
    end
  end

  context "PUT#update" do
    it "cannot update sac remarks" do
      expect do
        put :update, params: {id: admin.id, group_id: admin.groups.first.id,
                              # rubocop:todo Layout/LineLength
                              person: {sac_remark_national_office: "example", sac_remark_section_1: "example"}}
        # rubocop:enable Layout/LineLength
      end.not_to change {
                   [admin.reload.sac_remark_national_office, admin.reload.sac_remark_section_1]
                 }
    end

    it "runs data quality check only once" do
      data_quality_checker = instance_spy(People::DataQualityChecker)
      allow(People::DataQualityChecker).to receive(:new).and_return(data_quality_checker)

      expect do
        put :update, params: {id: admin.id, group_id: admin.groups.first.id, person: {
          first_name: nil,
          phone_number_landline_attributes: {number: "+41 77 123 45 66"}
        }}
      end.to change { admin.phone_numbers.count }.by(1)
      expect(data_quality_checker).to have_received(:check_data_quality).once
    end

    context "birthday" do
      let(:member) { people(:mitglied) }

      it "can update birthday on people without sac membership" do
        expect do
          put :update, params: {id: admin.id, group_id: admin.groups.first.id,
                                person: {birthday: "01.01.2001"}}
        end.to change { admin.reload.birthday }
      end

      it "can update birthday on people with neuanmeldung role" do
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          person: admin)

        expect do
          put :update, params: {id: admin.id, group_id: admin.groups.first.id,
                                person: {birthday: "01.01.2001"}}
        end.to change { admin.reload.birthday }
      end

      it "cannot remove birthday on people with neuanmeldung role" do
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          person: admin)

        expect do
          put :update, params: {id: admin.id, group_id: admin.groups.first.id,
                                person: {birthday: ""}}
        end.to_not change { admin.reload.birthday }
      end

      it "can update birthday as backoffice user" do
        expect do
          put :update, params: {id: member.id, group_id: member.groups.first.id,
                                person: {birthday: "01.01.2001"}}
        end.to change { member.reload.birthday }
      end

      it "cannot update birthday as non backoffice user" do
        sign_in(member)

        expect do
          put :update, params: {id: member.id, group_id: member.groups.first.id,
                                person: {birthday: "01.01.2001"}}
        end.not_to change { member.reload.birthday }

        expect(response.body).to include("Geburtsdatum darf nicht verändert werden")
      end

      it "cannot update birthday to last 6 years" do
        expect do
          put :update, params: {id: member.id, group_id: member.groups.first.id,
                                person: {birthday: 5.years.ago}}
        end.not_to change { member.reload.birthday }

        # rubocop:todo Layout/LineLength
        expect(response.body).to include("Geburtsdatum muss vor dem #{6.years.ago.to_date.strftime("%d.%m.%Y")} liegen.")
        # rubocop:enable Layout/LineLength
      end

      it "cannot update birthday to before 120 years ago" do
        expect do
          put :update, params: {id: member.id, group_id: member.groups.first.id,
                                person: {birthday: 121.years.ago}}
        end.not_to change { member.reload.birthday }

        # rubocop:todo Layout/LineLength
        expect(response.body).to include("Geburtsdatum muss nach dem #{120.years.ago.to_date.strftime("%d.%m.%Y")} liegen.")
        # rubocop:enable Layout/LineLength
      end

      it "does not validate if birthday was not changed" do
        member.update_attribute(:birthday, 121.years.ago) # invalid birthday

        put :update, params: {id: member.id, group_id: member.groups.first.id,
                              person: {first_name: "changed"}}

        expect(response).to have_http_status(303)

        member.reload

        expect(member.first_name).to eq("changed")
        # rubocop:todo Layout/LineLength
        expect(response.body).to_not include("Geburtsdatum muss nach dem 31.12.#{Date.current.year - 120} liegen.")
        # rubocop:enable Layout/LineLength
      end
    end

    context "email" do
      let(:member) { people(:mitglied) }

      subject(:request) do
        put :update, params: {id: member.id, group_id: member.groups.first.id, person: {email: nil}}
      end

      it "can set empty email as backoffice user" do
        expect { request }.to change { member.reload.email }.to(nil)
      end

      it "cannot set empty email as non backoffice user" do
        sign_in(people(:familienmitglied))
        expect { request }.to raise_error(CanCan::AccessDenied)
      end

      it "cannot set empty email as self" do
        sign_in(member)
        expect { request }.not_to change { member.reload.email }
      end

      it "can save with empty email as self if email was already empty before" do
        sign_in(member)
        expect { request }.not_to change { member.reload.email }
      end
    end

    it "can update phone_numbers" do
      expect do
        put :update, params: {id: admin.id, group_id: admin.groups.first.id,
                              person: {
                                phone_number_landline_attributes: {number: "+41 77 123 45 66"},
                                phone_number_mobile_attributes: {number: "+41 77 123 45 67"}
                              }}
      end.to change { admin.reload.phone_numbers.count }.by(2)
        .and change { admin.phone_number_landline&.number }.to("+41 77 123 45 66")
        .and change { admin.phone_number_mobile&.number }.to("+41 77 123 45 67")
    end

    it "can remove phone_numbers" do
      admin.create_phone_number_landline(number: "+41 77 123 45 66")

      expect do
        put :update, params: {id: admin.id, group_id: admin.groups.first.id,
                              person: {
                                phone_number_landline_attributes: {
                                  id: admin.phone_number_landline.id,
                                  number: ""
                                }
                              }}
      end.to change { admin.reload.phone_numbers.count }.by(-1)
        .and change { admin.phone_number_landline&.number }.from("+41 77 123 45 66").to(nil)
    end

    it "can update advertising" do
      expect do
        put :update,
          params: {id: admin.id, group_id: admin.groups.first.id, person: {advertising: false}}
      end.to change { admin.reload.advertising }.from(true).to(false)
    end
  end
end
