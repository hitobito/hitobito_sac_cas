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
    moments = [:today] unless end_of_year?

    moments.each do |moment|
      people_with_expiring_qualifications(moment).each do |person_id|
        Qualifications::ExpirationMailer.reminder(moment, person_id).deliver_later
      end
    end
  end

  def people_with_expiring_qualifications(moment)
    Qualifications::Expiring.entries(send(moment))
      .joins(:person)
      .where.not(people: {email: [nil, ""]})
      .distinct
      .pluck(:person_id)
  end

  def end_of_year?
    today == today.end_of_year
  end

  def today
    @today ||= Time.zone.today
  end

  def next_year
    1.year.from_now.all_year
  end

  def year_after_next_year
    2.years.from_now.all_year
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
