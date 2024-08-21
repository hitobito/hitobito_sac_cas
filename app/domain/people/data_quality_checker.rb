# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::DataQualityChecker
  ATTRIBUTES_TO_CHECK = %w[email street zip_code town first_name last_name
    company_name phone_numbers birthday]

  def initialize(person)
    @person = person

    check_invoice_recipient if @person.sac_membership_invoice?
    check_stammsektion if @person.roles.exists?(type: SacCas::STAMMSEKTION_ROLES)

    if @person.company?
      check("warning", "company_name", "empty", invalid: @person.company_name.blank?)
    else
      check("error", "first_name", "empty", invalid: @person.first_name.blank?)
      check("error", "last_name", "empty", invalid: @person.last_name.blank?)
    end

    highest_severity = @person.data_quality_issues.order(severity: :desc).first&.severity
    @person.update!(data_quality: highest_severity || "ok")
  end

  private

  def check_invoice_recipient
    check("error", "street", "empty", invalid: @person.street.blank?)
    check("error", "zip_code", "empty", invalid: @person.zip_code.blank?)
    check("error", "town", "empty", invalid: @person.town.blank?)
    check("warning", "email", "empty", invalid: @person.email.blank?)
    check("warning", "phone_numbers", "empty", invalid: @person.phone_numbers.blank?)
  end

  def check_stammsektion
    join_date = @person.roles.find_by(type: SacCas::STAMMSEKTION_ROLES).created_at

    check("error", "birthday", "empty", invalid: @person.birthday.blank?)
    check("warning", "birthday", "less_than_6_years_before_entry",
      invalid: @person.birthday.present? && (@person.birthday > join_date - 6.years))
  end

  def check(severity, attr, key, invalid: false)
    if invalid
      begin
        @person.data_quality_issues.create!(severity: severity, attr: attr, key: key)
      rescue
        nil
      end
    else
      @person.data_quality_issues.find_by(severity: severity, attr: attr, key: key)&.destroy!
    end
  end
end
