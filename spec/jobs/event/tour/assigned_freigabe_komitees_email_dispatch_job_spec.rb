# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

class Group::FreigabeKomitee::SomeDifferentRole < ::Group::FreigabeKomitee::Pruefer
end

describe Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob do
  include ActiveJob::TestHelper

  let(:tour) { events(:section_tour) }

  subject(:job) { described_class.new(:publication, tour.id) }

  before do
    CustomContent.init_section_specific_contents(tour.groups.first)
  end

  it "sends email to all people in assigned freigabe komitee" do
    Fabricate(Group::FreigabeKomitee::Pruefer.sti_name,
      person: people(:mitglied),
      group: groups(:bluemlisalp_freigabekomitee))

    expect { subject.perform }
      .to have_enqueued_mail(Event::TourMailer, :publication).with(tour, people(:mitglied))
  end

  it "does not send any emails if there is no assigned freigabe komitee" do
    tour.groups.first.event_approval_commission_responsibilities.destroy_all

    expect { subject.perform }
      .not_to have_enqueued_mail(Event::TourMailer, :publication)
  end

  it "does not send any emails for people with different role type than pruefer" do
    allow_any_instance_of(Group::FreigabeKomitee::SomeDifferentRole).to receive(:assert_type_is_allowed_for_group)
      .and_return(true)
    Group::FreigabeKomitee::SomeDifferentRole.create!(
      person: people(:mitglied),
      group: groups(:bluemlisalp_freigabekomitee)
    )

    expect { subject.perform }
      .not_to have_enqueued_mail(Event::TourMailer, :publication)
  end
end
