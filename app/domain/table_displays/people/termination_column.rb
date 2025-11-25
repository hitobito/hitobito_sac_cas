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
        allowed_value_for(person)
      end
    end

    private

    def allowed_value_for(person, target_attr = nil, &block)
      role = terminated_role(person)
      value(role) if role
    end

    def value(terminated_role)
      raise NotImplementedError, "Implement this method in subclass"
    end

    def membership_roles(person)
      person.roles_with_ended_readable.select do |role|
        SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name).include?(role.type)
      end
    end

    def terminated_role(person)
      role = membership_roles(person).select(&:end_on).max_by(&:end_on)
      role&.terminated? ? role : nil
    end
  end
end
