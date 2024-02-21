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
    end
  end

  def self_terminatable_own_role
    return false unless her_own
    return true unless mitglied_role?

    !has_termination_by_section_only_role
  end

  private

  def has_termination_by_section_only_role
    return mitglied_termination_by_section_only? if mitglied_zusatzsektion_role?

    subject.person.roles.
      select { |r| mitglied_role?(r) }.
      any? { |r| mitglied_termination_by_section_only?(r) }
  end

  def mitglied_role?(role = subject)
    SacCas::MITGLIED_ROLES.include?(role.class)
  end

  def mitglied_hauptsektion_role?(role = subject)
    SacCas::MITGLIED_HAUPTSEKTION_ROLES.include?(role.class)
  end

  def mitglied_zusatzsektion_role?(role = subject)
    SacCas::MITGLIED_ZUSATZSEKTION_ROLES.include?(role.class)
  end

  def mitglied_termination_by_section_only?(role = subject)
    role.
      group.
      ancestors.
      reverse.
      find { |g| [Group::Sektion, Group::Ortsgruppe].include?(g.class) }&.
      mitglied_termination_by_section_only
  end
end
