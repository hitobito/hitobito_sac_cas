# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class TerminationColumn < TableDisplays::Column
    prepend TableDisplays::People::SektionMemberAdminVisible

    def required_model_attrs(attr)
      []
    end

    def required_permission(attr)
      :show_full
    end

    def required_model_includes(attr)
      [:roles_with_ended_readable]
    end

    def render(attr)
      super do |person|
        value(terminated_role(person)) if terminated_role(person).present? && membership_roles(person).select(&:active?).blank?
      end
    end

    private

    def allowed_value_for(target, target_attr, &block)
      value(terminated_role(target)) if terminated_role(target).present? && membership_roles(target).select(&:active?).blank?
    end

    def value(terminated_role)
      raise NotImplementedError, "Implement this method in subclass"
    end

    def membership_roles(person)
      person.roles_with_ended_readable.select { |role| SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name).include?(role.type) }
    end

    def terminated_role(person)
      membership_roles(person).select(&:ended?).max_by(&:end_on)
    end
  end
end
