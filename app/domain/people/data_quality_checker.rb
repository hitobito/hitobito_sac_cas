# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::DataQualityChecker
  ATTRIBUTES_TO_CHECK = %w[first_name last_name company_name street zip_code town email phone_numbers birthday].freeze

  attr_reader :person

  def initialize(person)
    @person = person
  end

  def check_data_quality
    check_blank(:company_name, person.company?, :warning)
    check_blank(:first_name, !person.company?)
    check_blank(:last_name, !person.company?)
    check_blank(:street, membership_invoice?)
    check_blank(:zip_code, membership_invoice?)
    check_blank(:town, membership_invoice?)
    check_blank(:email, membership_invoice?, :warning)
    check_phone_numbers
    check_birthday

    update_person_data_quality
  end

  class << self
    def attributes_to_check_changed?(person)
      (person.saved_changes.keys & ATTRIBUTES_TO_CHECK).any?
    end
  end

  private

  def check_phone_numbers
    invalid = membership_invoice? && !@person.phone_numbers.any?
    create_or_destroy(invalid, attr: :phone_numbers, severity: :warning)
  end

  def check_birthday
    stammsektion = sac_membership.stammsektion_role

    check_blank(:birthday, stammsektion.present?)

    invalid = stammsektion.present? && person.birthday && person.birthday > stammsektion.created_at - 6.years
    create_or_destroy(invalid, attr: :birthday, severity: :warning, key: :less_than_6_years_before_entry)
  end

  def check_blank(attr, precondition, severity = :error)
    invalid = precondition && @person.send(attr).blank?
    create_or_destroy(invalid, attr: attr, severity: severity)
  end

  def create_or_destroy(invalid, attr:, key: :empty, severity: :error)
    existing_issue = issues.find { |issue| issue.attr == attr.to_s && issue.key == key.to_s }

    if !invalid
      existing_issue&.destroy!
    elsif existing_issue.nil?
      issues.create!(attr: attr, key: key, severity: severity)
    end
  end

  def update_person_data_quality
    highest_severity = find_highest_severity
    person.update_column(:data_quality, highest_severity) unless person.data_quality == highest_severity
  end

  def find_highest_severity
    issues.reject(&:destroyed?).max_by { |i| Person::DataQualityIssue.severities[i.severity] }&.severity || "ok"
  end

  def sac_membership
    @sac_membership ||= People::SacMembership.new(@person, in_memory: true)
  end

  def membership_invoice?
    return @membership_invoice if defined?(@membership_invoice)

    @membership_invoice = sac_membership.invoice?
  end

  def issues
    person.data_quality_issues
  end
end
