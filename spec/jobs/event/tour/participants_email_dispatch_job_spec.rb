# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour::ParticipantsEmailDispatchJob do
  include ActiveJob::TestHelper

  let(:tour) { events(:section_tour) }
  let(:sektion) { tour.groups.first }
  let!(:participation) {
    Fabricate(:event_participation, event: tour, participant: people(:mitglied), state: "annulled")
  }
  let!(:participation_2) {
    Fabricate(:event_participation, event: tour, participant: people(:admin), state: "attended")
  }

  before do
    CustomContent.init_section_specific_contents(sektion)
    Event::Tour::Role::Participant.create!(participation: participation, event: tour)
    Event::Tour::Role::Participant.create!(participation: participation_2, event: tour)
  end

  context "participation mail" do
    subject(:job) { described_class.new(:canceled_weather, tour.id, ["attended", "annulled"]) }

    it "sends email to participant in all passed states" do
      expect { subject.perform }
        .to have_enqueued_mail(Event::TourParticipationMailer, :canceled_weather).with(participation)
        .and have_enqueued_mail(Event::TourParticipationMailer, :canceled_weather).with(participation_2)
    end

    it "does not send email to participation in different state" do
      participation_2.update_column(:state, :unconfirmed)

      expect { subject.perform }
        .to have_enqueued_mail(Event::TourParticipationMailer, :canceled_weather).with(participation)
        .and not_have_enqueued_mail(Event::TourParticipationMailer, :canceled_weather).with(participation_2)
    end
  end

  context "person mail" do
    subject(:job) { described_class.new(:publication, tour.id, ["attended", "annulled"]) }

    it "sends email to all leaders in tour" do
      expect { subject.perform }
        .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
        .and have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:admin))
    end

    it "does not send emails to tour participants" do
      participation_2.update_column(:state, :unconfirmed)

      expect { subject.perform }
        .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
        .and not_have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:admin))
    end
  end
end
