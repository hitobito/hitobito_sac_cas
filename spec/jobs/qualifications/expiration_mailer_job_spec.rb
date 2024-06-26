# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Qualifications::ExpirationMailerJob do
  before do
    ActionMailer::Base.deliveries.clear
    load './db/seeds/custom_contents.rb'
  end

  subject(:job) { described_class.new }

  let(:person) { people(:mitglied) }
  let(:qualification) do
    person.qualifications.create!(
      qualification_kind: qualification_kinds(:ski_leader),
      start_at: '2000-01-01'.to_date,
      finish_at: finish_at
    )
  end

  context 'rescheduling' do
    it 'reschedules for tomorrow at 5 minutes past midnight' do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%ExpirationMailerJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context 'qualification expires today' do
    let(:finish_at) { '2000-01-01'.to_date }

    it 'mails a reminder' do
      qualification
      travel_to '2000-01-01'.to_date
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'doesn\'t mail a reminder if another qualification is still active' do
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: '2000-01-01'.to_date,
        finish_at: '2001-06-01'.to_date
      )
      qualification
      travel_to '2000-01-01'.to_date
      expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  context 'qualification expires within 1 day' do
    let(:finish_at) { '2001-01-01'.to_date }

    it 'mails a reminder because it expires within 1 year' do
      qualification
      travel_to '2000-12-31'.to_date
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end

  context 'qualification expires within 1 year' do
    let(:finish_at) { '2001-06-01'.to_date }

    it 'mails a reminder' do
      qualification
      travel_to '2000-12-31'.to_date
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end

  context 'qualification expires within 2 years' do
    let(:finish_at) { '2002-06-01'.to_date }

    it 'mails a reminder' do
      qualification
      travel_to '2000-12-31'.to_date
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end

  context 'qualification expires within 3 years' do
    let(:finish_at) { '2003-06-01'.to_date }

    it 'doesn\'t mail a reminder' do
      qualification
      travel_to '2000-12-31'.to_date
      expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  context 'with multiple people' do
    let(:admin) { people(:admin) }
    let(:finish_at) { '2001-06-01'.to_date }

    it 'mails a reminder' do
      qualification
      admin.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: '2000-01-01'.to_date,
        finish_at: finish_at
      )
      travel_to '2000-12-31'.to_date
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(2)
    end
  end
end
