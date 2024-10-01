# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Courses::KeyDataSheetsController do
  before { sign_in(user) }

  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }

  let!(:leader_participations) do
    [Event::Role::Leader, Event::Role::AssistantLeader].map do |event_role|
      Fabricate(event_role.name.to_sym,
        participation: Fabricate(:event_participation, event: event)).participation
    end
  end

  let!(:regular_participations) do
    (0..4).to_a.map do
      Fabricate(:event_participation, event: event)
    end
  end

  describe "POST #create" do
    context "as member" do
      let(:user) { people(:mitglied) }

      it "unauthorized" do
        expect do
          post :create, params: {group_id: group, event_id: event}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:user) { people(:admin) }

      it "attaches key data sheets for each event leader to event" do
        expect(event.attachments.count).to eq(0)

        expect do
          post :create, params: {group_id: group, event_id: event}
        end.to change { Event::Attachment.count }.by(2)

        expect(event.attachments.count).to eq(2)

        filenames = event.attachments.map { _1.file.filename.to_s }

        expected_filenames = leader_participations.map {
          _1.reload
          Export::Pdf::Participations::KeyDataSheet.new(_1).filename
        }

        expect(filenames).to match_array(expected_filenames)
      end

      it "attaches key data sheet for specific event leader to event" do
        participation = leader_participations.first
        expect(event.attachments.count).to eq(0)

        expect do
          post :create, params: {group_id: group, event_id: event, participation_ids: participation.id.to_s}
        end.to change { Event::Attachment.count }.by(1)

        expect(event.attachments.count).to eq(1)

        filename = event.attachments.first.file.filename.to_s

        participation.reload
        expected_filename = Export::Pdf::Participations::KeyDataSheet.new(participation).filename

        expect(filename).to eq(expected_filename)
      end

      it "does not attach key data sheet for regular participant" do
        participation = regular_participations.first
        expect(event.attachments.count).to eq(0)

        expect do
          post :create, params: {group_id: group, event_id: event, participation_ids: participation.id.to_s}
        end.to_not change { Event::Attachment.count }

        expect(event.attachments.count).to eq(0)
      end
    end
  end
end
