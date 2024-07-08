# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacMembership
  def initialize(person)
    @person = person
  end

  def active?
    stammsektion_role.present?
  end

  def terminated?
    stammsektion_role&.terminated?
  end

  # checks for any active membership roles
  def active_in?(sac_section)
    @person.roles.exists?(group_id: sac_section.children,
      type: mitglied_types)
  end

  # checkes for active and also approvabable (neuanmeldung) roles
  def active_or_approvable_in?(sac_section)
    @person.roles.exists?(group_id: sac_section.children,
      type: mitglied_and_neuanmeldung_types)
  end

  def anytime?
    stammsektion_role.present? || any_future_role? || any_past_role?
  end

  def stammsektion_role
    if @person.roles.is_a?(ActiveRecord::Relation)
      @person.roles.find_by(type: mitglied_stammsektion_types)
    else
      @person.roles.find { |r| mitglied_stammsektion_types.include?(r.type) }
    end
  end

  def future_stammsektion_roles
    @person.roles.future.where(convert_to: mitglied_stammsektion_types)
  end

  def zusatzsektion_roles
    @person.roles.where(type: mitglied_zusatzsektion_types)
  end

  # Here for documentation purposes only as there is no such thing as future zusatzsektion roles.
  # If this changes in the future, future_zusatzsektion_roles must be handled in
  # `Memberships::FamilyMutation` as well.
  def future_zusatzsektion_roles
    raise "there is no such thing as future zusatzsektion roles"
  end

  def billable?
    active? || @person.roles.any? { |r| r.is_a?(Invoices::SacMemberships::Member::NEW_ENTRY_ROLE) }
  end

  def family?
    stammsektion_role&.beitragskategorie&.family? || false
  end

  def family_id
    return unless family?

    @person.household_key.start_with?("F") ? @person.household_key : "F#{@person.household_key}"
  end

  private

  def mitglied_types = SacCas::MITGLIED_ROLES.map(&:sti_name)

  def mitglied_stammsektion_types = SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name)

  def mitglied_zusatzsektion_types = SacCas::MITGLIED_ZUSATZSEKTION_ROLES.map(&:sti_name)

  def mitglied_and_neuanmeldung_types = SacCas::MITGLIED_AND_NEUANMELDUNG_ROLES.map(&:sti_name)

  def any_future_role?
    @person.roles.future.where(convert_to: mitglied_stammsektion_types).exists?
  end

  def any_past_role?
    @person.roles.deleted.where(type: mitglied_stammsektion_types).exists?
  end
end
