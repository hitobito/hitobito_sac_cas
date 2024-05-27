# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::CloseApplicationsJob do
  subject(:job) { described_class.new }

  context 'rescheduling' do
    it 'reschedules for tomorrow  at 5 minutes past midnight' do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%CloseApplicationsJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context 'application_open' do
    let(:course) { Fabricate(:sac_open_course) }
    it 'updates course state when application_closing_at is in the past' do
      travel_to(course.application_closing_at + 1.day) do
        expect { job.perform }.to change { course.reload.state }.to('application_closed')
      end
    end

    it 'keeps course state when application_closing_at is today' do
      travel_to(course.application_closing_at) do
        expect { job.perform }.not_to change { course.reload.state }
      end
    end
  end

  context 'application_paused' do
    let(:course) do
      course = Fabricate(:sac_open_course)
      course.update!(state: :application_paused)
      course
    end
    it 'updates course state when application_closing_at is in the past' do
      travel_to(course.application_closing_at + 1.day) do
        expect { job.perform }.to change { course.reload.state }.to('application_closed')
      end
    end

    it 'keeps course state when application_closing_at is today' do
      travel_to(course.application_closing_at) do
        expect { job.perform }.not_to change { course.reload.state }
      end
    end
  end
end
