# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour::LeadersEmailDispatchJob do
  include ActiveJob::TestHelper

  let(:tour) { events(:section_tour) }
  let(:sektion) { tour.groups.first }
  let(:participation) { Fabricate(:event_participation, event: tour, participant: people(:mitglied)) }

  before do
    CustomContent.init_section_specific_contents(sektion)
  end

  context "participation mail" do
    subject(:job) { described_class.new(:canceled_weather, tour.id) }

    it "sends email to all leaders in tour" do
      Fabricate(Event::Role::Leader.name.to_sym, participation: participation)

      expect { subject.perform }
        .to have_enqueued_mail(Event::TourParticipationMailer, :canceled_weather).with(participation)
    end

    it "does not send emails to tour participants" do
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation)

      expect { subject.perform }
        .not_to have_enqueued_mail(Event::TourParticipationMailer, :canceled_weather)
    end
  end

  context "person mail" do
    subject(:job) { described_class.new(:publication, tour.id) }

    it "sends email to all leaders in tour" do
      Fabricate(Event::Role::Leader.name.to_sym, participation: participation)

      expect { subject.perform }
        .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
    end

    it "does not send emails to tour participants" do
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation)

      expect { subject.perform }
        .not_to have_enqueued_mail(Event::TourMailer, :publication)
    end
  end
end
