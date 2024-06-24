# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacMembership

  MEMBERSHIP_ROLES = [
    Group::SektionsMitglieder::Mitglied
  ].freeze

  def initialize(person)
    @person = person
    @roles = MEMBERSHIP_ROLES.map(&:sti_name)
    @active_or_approvable_roles = SacCas::MITGLIED_HAUPTSEKTION_ROLES.map(&:sti_name)
  end

  def active?
    roles.any?
  end

  # checks for any active membership roles
  def active_in?(sac_section)
    @person.roles.exists?(group_id: sac_section.children,
                          type: @roles)
  end

  # checkes for active and also approvabable (neuanmeldung) roles
  def active_or_approvable_in?(sac_section)
    @person.roles.exists?(group_id: sac_section.children,
                          type: @active_or_approvable_roles)
  end

  def anytime?
    roles.any? || any_future_role? || any_past_role?
  end

  def roles
    @person.roles.select { |r| MEMBERSHIP_ROLES.include?(r.class) }
  end

  # There should be only one active `Mitglied` role at a time anyway
  def role
    roles.first
  end

  def billable?
    active? || @person.roles.any? { |r| r.is_a?(Invoices::SacMemberships::Member::NEW_ENTRY_ROLE) }
  end

  private

  def any_future_role?
    @person.roles.future.where(convert_to: @roles).exists?
  end

  def any_past_role?
    @person.roles.deleted.where(type: @roles).exists?
  end
end
