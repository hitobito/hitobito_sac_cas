# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ParticipationRejectionJob do
  subject(:job) { described_class.new(rejected_participation) }

  let(:course) { events(:closed) }

  context "when application was rejected" do
    let(:application) { Fabricate(:event_application, priority_1: course, rejected: true) }
    let(:rejected_participation) {
      Fabricate(:event_participation, event: course,
        application: application, state: "rejected")
    }

    it "sends the rejection email" do
      expect {
        rejected_participation
        course.update!(state: :assignment_closed)
      }.to change { Delayed::Job.where("handler LIKE ?", "%ParticipationRejectionJob%").count }.by(1)

      Delayed::Job.last.payload_object.perform

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq("Kursablehnung")
    end
  end
end
