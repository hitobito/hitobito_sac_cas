# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Qualification::ExpirationMailer < ApplicationMailer
  MOMENTS = %i[today next_year next_two_years]
  REMINDER_TODAY = 'qualification_expiration_reminder_today'
  REMINDER_NEXT_YEAR = 'qualification_expiration_reminder_next_year'
  REMINDER_NEXT_TWO_YEARS = 'qualification_expiration_reminder_next_two_years'

  def reminder(moment, person)
    return unless MOMENTS.include?(moment)

    content_key = Qualification::ExpirationMailer.const_get(:"REMINDER_#{moment.upcase}")
    compose(person, content_key)
  end
end
