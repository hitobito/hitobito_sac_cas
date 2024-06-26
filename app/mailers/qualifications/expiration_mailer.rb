# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Qualifications::ExpirationMailer < ApplicationMailer
  MOMENTS = %i[today next_year year_after_next_year].freeze
  REMINDER_TODAY = 'qualification_expiration_reminder_today'
  REMINDER_NEXT_YEAR = 'qualification_expiration_reminder_next_year'
  REMINDER_YEAR_AFTER_NEXT_YEAR = 'qualification_expiration_reminder_year_after_next_year'

  def reminder(moment, person)
    return unless MOMENTS.include?(moment)

    compose(person, content_key(moment))
  end

  private

  def content_key(moment)
    self.class.const_get(:"REMINDER_#{moment.upcase}")
  end
end
