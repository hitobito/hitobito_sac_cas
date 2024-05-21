# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::GroupDecorator

  def members_count
    return unless sektion_or_ortsgruppe?

    object.children.flat_map(&:roles).select do |role|
      (SacCas::MITGLIED_ROLES - SacCas::NEUANMELDUNG_ROLES).include?(role.class)
    end.size
  end

  def membership_admission_through_gs?
    return unless sektion_or_ortsgruppe?

    object.children.none? { |group| group.is_a?(Group::SektionsNeuanmeldungenSektion) }
  end

  def membership_self_registration_url
    return unless sektion_or_ortsgruppe?

    object.sac_cas_self_registration_url(helpers.request.host)
  end

  def has_youth_organization?
    return unless sektion_or_ortsgruppe?

    object.social_accounts.any? { |account| account.label == 'Homepage JO' }
  end

  # Sort roles alphabetically, but make "Andere" show up last.
  def role_types
    klass.role_types.sort_by { |role| [role.name.demodulize.eql?('Andere') ? 1 : 0, role.label] }
  end
end
