# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::DataQualityChecker
  CHECKS_TO_PERFORM = [
    [:company_name, :warning, check?: ->(p) { p.company? }],
    [:first_name, :error, check?: ->(p) { !p.company? }],
    [:last_name, :error, check?: ->(p) { !p.company? }],
    [:street, :error, check?: ->(p) { p.sac_membership_invoice? }],
    [:zip_code, :error, check?: ->(p) { p.sac_membership_invoice? }],
    [:town, :error, check?: ->(p) { p.sac_membership_invoice? }],
    [:email, :warning, check?: ->(p) { p.sac_membership_invoice? }],
    [:phone_numbers, :warning, check?: ->(p) { p.sac_membership_invoice? }],
    [:birthday, :error, check?: ->(p) { p.roles.exists?(type: SacCas::STAMMSEKTION_ROLES) }],
    [:birthday, :warning, check?: ->(p) { p.roles.exists?(type: SacCas::STAMMSEKTION_ROLES) },
                          invalid?: ->(p) { birthday_less_than_6_years_before_entry(p) },
                          key: :less_than_6_years_before_entry]
  ]
  ATTRIBUTES_TO_CHECK = CHECKS_TO_PERFORM.map(&:first).map(&:to_s).uniq

  def initialize(person)
    @person = person
  end

  def check_data_quality
    CHECKS_TO_PERFORM.each do |attr, severity, checks|
      next unless checks[:check?].call(@person)

      issue = {severity: severity, attr: attr, key: checks[:key] || :empty}
      invalid = checks[:invalid?].nil? ? @person.send(attr).blank? : checks[:invalid?].call(@person)

      create_or_destroy(issue, invalid)
    end

    highest_severity = @person.data_quality_issues.order(severity: :desc).first&.severity
    @person.update!(data_quality: highest_severity || :ok)
  end

  def self.birthday_less_than_6_years_before_entry(person)
    return if person.birthday.blank?

    person.birthday > person.roles.find_by(type: SacCas::STAMMSEKTION_ROLES).created_at - 6.years
  end

  private

  def create_or_destroy(issue, invalid)
    existing_issue = @person.data_quality_issues.find_by(issue)

    return existing_issue&.destroy! unless invalid

    @person.data_quality_issues.create!(issue) if existing_issue.nil?
  end
end
