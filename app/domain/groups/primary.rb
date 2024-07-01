# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Groups
  class Primary
    ROLE_TYPES = SacCas::STAMMSEKTION_ROLES.map(&:sti_name).freeze

    GROUP_TYPES = ROLE_TYPES.collect(&:deconstantize).freeze

    def initialize(person)
      @person = person
      @primary_group = person.primary_group
    end

    # Returns the group of the first preferred role or the first role if no preferred role exists.
    def identify
      preferred_roles.first&.group || roles.first&.group
    end

    # Whether the person has at least one preferred role in the primary group.
    def preferred_exists?
      preferred_roles.where(group: @primary_group).exists?
    end

    # Whether the person has at least one preferred role in the given group.
    def preferred?(group)
      preferred_roles.collect(&:group).include?(group)
    end

    private

    def preferred_roles
      @preferred_roles ||= roles.where(type: ROLE_TYPES)
    end

    def roles
      @roles ||= @person.roles.order(:created_at)
    end
  end
end
