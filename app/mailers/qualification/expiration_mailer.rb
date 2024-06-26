# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Qualification::ExpirationMailer < ApplicationMailer
  MOMENTS = %i[today this_year next_year]
  REMINDER_TODAY = 'qualification_expiration_reminder_today'
  REMINDER_THIS_YEAR = 'qualification_expiration_reminder_this_year'
  REMINDER_NEXT_YEAR = 'qualification_expiration_reminder_next_year'

  def reminder(moment, person)
    return unless MOMENTS.include?(moment)

    compose(person, content_key(moment))
  end

  private

  def content_key(moment)
    self.class.const_get(:"REMINDER_#{moment.upcase}")
  end
end
