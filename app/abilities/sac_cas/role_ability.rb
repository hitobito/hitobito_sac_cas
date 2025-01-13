# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::RoleAbility
  extend ActiveSupport::Concern

  prepended do
    on(Role) do
      permission(:any).may(:terminate).self_terminatable_own_role
      general(:create, :update, :delete).if_admin_only_admin?
    end
  end

  def self_terminatable_own_role
    return false unless her_own
    return false if abonnent?
    return true unless mitglied_role?

    !has_termination_by_section_only_role
  end

  # core: general(:destroy).not_permission_giving
  def not_permission_giving
    return false if wizard_managed_role?

    super
  end

  def if_admin_only_admin?
    subject&.type&.safe_constantize&.permissions&.include?(:admin) ? if_admin : true
  end

  private

  def has_termination_by_section_only_role
    return mitglied_termination_by_section_only? if mitglied_zusatzsektion_role?

    subject.person.roles
      .select { |r| mitglied_role?(r) }
      .any? { |r| mitglied_termination_by_section_only?(r) }
  end

  def mitglied_role?(role = subject)
    SacCas::MITGLIED_ROLES.include?(role.class)
  end

  def mitglied_zusatzsektion_role?(role = subject)
    SacCas::MITGLIED_ZUSATZSEKTION_ROLES.include?(role.class)
  end

  def mitglied_termination_by_section_only?(role = subject)
    role
      .group
      .ancestors
      .reverse
      .find { |g| [Group::Sektion, Group::Ortsgruppe].include?(g.class) }
      &.mitglied_termination_by_section_only
  end

  def wizard_managed_role?(role = subject)
    SacCas::WIZARD_MANAGED_ROLES.include?(role.class)
  end

  def abonnent? = subject.is_a?(Group::AboMagazin::Abonnent)
end
