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
    if entry.birthday.year >= max_year
      add_error(:must_be_before_year, max_year)
    elsif entry.birthday.year < min_year
      add_error(:must_be_after_year, min_year)
    end
  end

  def add_error(error_type, year = nil)
    if year
      entry.errors.add(:birthday, I18n.t("activerecord.errors.models.person.birthday.#{error_type}", year: year))
    else
      entry.errors.add(:birthday, I18n.t("activerecord.errors.messages.#{error_type}"))
    end
    throw(:abort) # do not save record
  end

  def current_year = Time.current.year

  def max_year = current_year - 6

  def min_year = current_year - 120
end
