# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Courses::LeaderSettlementPdfsController do
  before { sign_in(user) }

  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course), start_point_of_time: :day, dates: [
      Event::Date.new(start_at: "01.06.2021", finish_at: "02.06.2021"),
      Event::Date.new(start_at: "07.06.2021", finish_at: "08.06.2021")
    ])
  end
  let(:group) { course.groups.first }
  let(:kurskader_group) { Group::SacCasKurskader.create!(parent: Group.root) }

  let!(:leader_participation) {
    Fabricate(Event::Course::Role::Leader.sti_name,
      participation: Fabricate(:event_participation, event: course)).participation
  }
  let!(:assistant_leader_participation) {
    Fabricate(Event::Course::Role::AssistantLeader.sti_name,
      participation: Fabricate(:event_participation, event: course)).participation
  }

  before do
    Group::SacCasKurskader::KursleitungSelbstaendig.create!(person: leader_participation.person, group: kurskader_group,
      start_on: Time.zone.local(2021, 5, 1))
    Group::SacCasKurskader::KlassenlehrerSelbstaendig.create!(person: leader_participation.person,
      group: kurskader_group, start_on: Time.zone.local(2021, 5, 1))
  end

  describe "POST #create" do
    context "as member" do
      let(:user) { people(:mitglied) }

      it "unauthorized" do
        expect do
          post :create,
            params: {group_id: group, event_id: course,
                     participation_id: leader_participation.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as leader_participation" do
      let(:user) { leader_participation.person }

      it "unauthorized if not his own participation" do
        expect do
          post :create,
            params: {group_id: group, event_id: course,
                     participation_id: assistant_leader_participation.id}
        end.to raise_error(CanCan::AccessDenied)
      end

      it "returns turbo frame when form is invalid" do
        # rubocop:todo Layout/LineLength
        expect_any_instance_of(Event::Courses::LeaderSettlementForm).to receive(:valid?).and_return(false)
        # rubocop:enable Layout/LineLength
        post :create, params: {group_id: group,
                               event_id: course,
                               participation_id: leader_participation.id,
                               event_courses_leader_settlement_form: {iban: "", actual_days: 2}}
        expect(response.media_type).to eq Mime[:turbo_stream]
      end

      it "starts export job when form is valid" do
        expect do
          post :create, params: {group_id: group,
                                 event_id: course,
                                 participation_id: leader_participation.id,
                                 event_courses_leader_settlement_form: {
                                   iban: "CH66 0076 2011 6238 5295 8", actual_days: 2
                                 }}
        end.to change {
                 Delayed::Job.where("handler like '%LeaderSettlementExportJob%'").count
               }.by(1)
      end
    end
  end
end
