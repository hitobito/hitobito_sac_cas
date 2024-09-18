# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::GroupDecorator
  def members_count
    return unless sektion_or_ortsgruppe?

    object.children.flat_map(&:roles).count do |role|
      (SacCas::MITGLIED_ROLES - SacCas::NEUANMELDUNG_ROLES).include?(role.class)
    end
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

    object.social_accounts.any? { |account| account.label == "Homepage JO" }
  end

  # Sort roles alphabetically, but make "Leserecht", "Schreibrecht" and "Andere" show up last.
  def role_types
    special_role_types = {
      Leserecht: 1,
      Schreibrecht: 1,
      Andere: 2
    }.with_indifferent_access
    klass.role_types.sort_by do |role|
      [special_role_types.fetch(role.name.demodulize, 0), role.label]
    end
  end

  def possible_roles
    role_types.select do |type|
      !type.restricted? && SacCas::WIZARD_MANAGED_ROLES.exclude?(type) &&
        (type.visible_from_above? || can?(:index_local_people, model))
    end
  end
end
