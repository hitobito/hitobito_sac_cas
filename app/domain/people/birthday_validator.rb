# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::BirthdayValidator
  attr_reader :entry, :current_user

  def initialize(entry, current_user)
    @entry = entry
    @current_user = current_user
  end

  def validate!
    if current_user.backoffice?
      validate_birthday_range
    else
      add_error(:readonly)
    end
  end

  def validate_birthday_range
    if entry.birthday > min_age_date
      add_error(:must_be_before, min_age_date) # Error for too young
    elsif entry.birthday < max_age_date
      add_error(:must_be_after, max_age_date) # Error for too old
    end
  end

  def add_error(error_type, date = nil)
    if date
      entry.errors.add(:birthday, I18n.t("activerecord.errors.models.person.birthday.#{error_type}", date: date.strftime("%d.%m.%Y")))
    else
      entry.errors.add(:birthday, I18n.t("activerecord.errors.messages.#{error_type}"))
    end
    throw(:abort) # Prevent saving the record
  end

  def min_age_date
    6.years.ago.to_date
  end

  def max_age_date
    120.years.ago.to_date
  end
end
