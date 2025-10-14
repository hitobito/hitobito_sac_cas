# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Export::Tabular::People::PersonRow
  def termination_reason
    return if terminated_role.nil? || membership_roles.select(&:active?).any?

    terminated_role.termination_reason_text
  end

  def terminate_on
    return if terminated_role.nil? || membership_roles.select(&:active?).any?

    I18n.l(terminated_role.end_on)
  end

  private

  def membership_roles
    entry.roles_unscoped.select { |role|
      SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name).include?(role.type)
    }
  end

  def terminated_role
    membership_roles.select(&:ended?).max_by(&:end_on)
  end
end
