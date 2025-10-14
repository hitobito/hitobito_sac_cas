# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::DataQualityChecker
  ATTRIBUTES_TO_CHECK = %w[first_name last_name street zip_code postbox town email phone_numbers
    birthday].freeze

  attr_reader :person

  def initialize(person)
    @person = person
  end

  def check_data_quality # rubocop:todo Metrics/AbcSize
    check_blank(:first_name, !person.company?)
    check_blank(:last_name, !person.company?)
    check_blank(:street, abacus_transmittable? && check_street?)
    check_blank(:zip_code, abacus_transmittable?)
    check_blank(:town, abacus_transmittable?)
    check_blank(:email, abacus_transmittable?, :warning)
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
    invalid = abacus_transmittable? && !@person.phone_numbers.any?
    create_or_destroy(invalid, attr: :phone_numbers, severity: :warning)
  end

  def check_birthday
    stammsektion = sac_membership.stammsektion_role

    check_blank(:birthday, stammsektion.present?)

    # rubocop:todo Layout/LineLength
    invalid = stammsektion.present? && person.birthday && person.birthday > stammsektion.created_at - 6.years
    # rubocop:enable Layout/LineLength
    create_or_destroy(invalid, attr: :birthday, severity: :warning,
      key: :less_than_6_years_before_entry)
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
    unless person.data_quality == highest_severity
      person.update_column(:data_quality,
        highest_severity)
    end
  end

  def find_highest_severity
    issues.reject(&:destroyed?).max_by { |i|
      Person::DataQualityIssue.severities[i.severity]
    }&.severity || "ok"
  end

  def sac_membership
    @sac_membership ||= People::SacMembership.new(@person, in_memory: true)
  end

  def abacus_transmittable?
    return @abacus_transmittable if defined?(@abacus_transmittable)

    @abacus_transmittable = sac_membership.invoice? || sac_membership.abonnent_magazin?
  end

  def check_street?
    person.dup.then do |p|
      Person::AddressValidator.new.validate(p)

      p.errors.attribute_names.include?(:street)
    end
  end

  def issues
    person.data_quality_issues
  end
end
