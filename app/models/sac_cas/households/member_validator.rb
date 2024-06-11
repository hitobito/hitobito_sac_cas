# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Households::MemberValidator
  extend ActiveSupport::Concern

  def validate(household_member)
    super(household_member)

    assert_birthday
    assert_family_age_range
    assert_no_conflicting_family_membership
    assert_no_membership_in_other_section
  end

  private

  def assert_birthday
    if person.birthday.blank?
      @member.errors.add(:base,
                         :birthday_missing,
                         person_name: person.full_name)
    end
  end

  def assert_family_age_range
    unless SacCas::Beitragskategorie::Calculator.new(person).family_age?
      @member.errors.add(:base,
                         :family_age_range_not_fulfilled,
                         person_name: person.full_name)
    end
  end

  def assert_no_conflicting_family_membership
    if person.household_key != household.household_key &&
        person.roles.where(beitragskategorie: :family).exists?
      @member.errors.add(:base, :conflicting_family_membership, name: person.full_name)
    end
  end

  def assert_no_membership_in_other_section
    if member_main_section != household_reference_person_main_section
      @member.errors.add(:base, :membership_in_other_section, person_name: person.full_name)
    end
  end

  def member_main_section
    Group::SektionsMitglieder::Mitglied.find_by(person_id: person.id)&.group
  end

  def household_reference_person_main_section
    Group::SektionsMitglieder::Mitglied.find_by(person_id: household.reference_person.id)&.group
  end
end
