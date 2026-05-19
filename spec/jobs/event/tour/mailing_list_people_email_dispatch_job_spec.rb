# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour::MailingListPeopleEmailDispatchJob do
  include ActiveJob::TestHelper

  let(:tour) { events(:section_tour) }
  let(:sektion) { tour.groups.first }
  let(:regular_mailing_list) { MailingList.find_by(internal_key: SacCas::MAILING_LIST_REGULAR_TOUR_INTERNAL_KEY) }
  let(:subito_mailing_list) { MailingList.find_by(internal_key: SacCas::MAILING_LIST_SUBITO_TOUR_INTERNAL_KEY) }

  subject(:job) { described_class.new(:publication, tour.id) }

  before do
    CustomContent.init_section_specific_contents(sektion)
    sektion.send(:create_tour_notification_mailing_lists)
  end

  context "regular tour" do
    before do
      tour.update_column(:subito, false)
    end

    it "sends email to all people in regular tour publication mailing list" do
      Fabricate(:subscription, mailing_list: regular_mailing_list, subscriber: people(:mitglied))

      expect { subject.perform }
        .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
    end

    it "does not send emails to subscribers of subito publication mailing list" do
      Fabricate(:subscription, mailing_list: subito_mailing_list, subscriber: people(:mitglied))

      expect { subject.perform }
        .not_to have_enqueued_mail(Event::TourMailer, :publication)
    end

    it "does not send emails if mailing list does not have any subscriber" do
      expect { subject.perform }
        .not_to have_enqueued_mail(Event::TourMailer, :publication)
    end
  end

  context "subito tour" do
    before do
      tour.update_column(:subito, true)
    end

    it "sends email to all people in subito tour publication mailing list" do
      Fabricate(:subscription, mailing_list: subito_mailing_list, subscriber: people(:mitglied))

      expect { subject.perform }
        .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
    end

    it "does not send emails to subscribers of regular publication mailing list" do
      Fabricate(:subscription, mailing_list: regular_mailing_list, subscriber: people(:mitglied))

      expect { subject.perform }
        .not_to have_enqueued_mail(Event::TourMailer, :publication)
    end

    it "does not send emails if mailing list does not have any subscriber" do
      expect { subject.perform }
        .not_to have_enqueued_mail(Event::TourMailer, :publication)
    end
  end
end
