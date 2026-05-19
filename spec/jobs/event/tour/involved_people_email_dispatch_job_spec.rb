# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour::InvolvedPeopleEmailDispatchJob do
  include ActiveJob::TestHelper

  let(:tour) { events(:section_tour) }

  subject(:job) { described_class.new(:publication, tour.id) }

  before do
    CustomContent.init_section_specific_contents(tour.groups.first)
    tour.update!(contact: people(:mitglied), updater: people(:familienmitglied))
  end

  it "sends email to all people in assigned freigabe komitee" do
    expect { subject.perform }
      .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
      .and have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:familienmitglied))
  end

  it "only sends one email if updater and contact person are the same" do
    tour.update!(updater: people(:mitglied))

    expect { subject.perform }
      .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied)).once
  end

  it "does not send any email if neither contact or updater are present" do
    tour.update!(updater: nil, contact: nil)

    expect { subject.perform }
      .not_to have_enqueued_mail(Event::TourMailer, :publication)
  end
end
