# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Qualification::ExpirationMailerJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    moments = Qualification::ExpirationMailer::MOMENTS
    moments = [moments.first] unless end_of_year?

    moments.each do |moment|
      Qualification::Expiring.entries(send(moment)).each do |qualification|
        Qualification::ExpirationMailer.reminder(moment, qualification.person).deliver_now
      end
    end
  end

  def end_of_year?
    today == today.end_of_year
  end

  def today
    Time.zone.today
  end

  def next_year
    1.year.from_now.all_year
  end

  def next_two_years
    2.years.from_now.all_year
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
