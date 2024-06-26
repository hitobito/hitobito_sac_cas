# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Qualifications::ExpirationMailerJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    moments = Qualifications::ExpirationMailer::MOMENTS
    moments = [moments.first] unless end_of_year?

    moments.each do |moment|
      expiring_qualifications(moment).each do |qualification|
        Qualifications::ExpirationMailer.reminder(moment, qualification.person).deliver_now
      end
    end
  end

  def expiring_qualifications(moment)
    Qualifications::Expiring.entries(send(moment))
  end

  def end_of_year?
    today == today.end_of_year
  end

  def today
    Time.zone.today
  end

  def this_year
    1.year.from_now.all_year
  end

  def next_year
    2.years.from_now.all_year
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
