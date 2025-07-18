# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Course, type: :model do
  describe "cancelling" do
    before { ActiveJob::Base.queue_adapter = :test }

    let(:course) { events(:top_course) }

    before do
      # Course has multiple participations that are not canceled or annulled
      expect(course.participations.where.not(state: [:canceled, :annulled]))
        .to have(2).items

      # Configure the course to inform participants
      course.inform_participants = 1
    end

    it "sends canceled email for all participations" do
      expect { course.update!(state: :canceled, canceled_reason: "weather") }
        .to have_enqueued_mail(Event::CanceledMailer, :weather).twice
    end

    it "does not send canceled email for annulled participations" do
      # One participant cancels
      course.participations.first.update!(state: :canceled, canceled_at: Time.current)

      expect { course.update!(state: :canceled, canceled_reason: "weather") }
        .to have_enqueued_mail(Event::CanceledMailer, :weather).once
    end
  end
end
