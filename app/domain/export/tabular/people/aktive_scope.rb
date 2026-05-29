# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class AktiveScope
    attr_reader :reference_date, :group, :relevant_role_types

    # group should be a Group::SektionMitglieder or nil for the entire SAC
    def initialize(reference_date, group = nil, relevant_role_types: nil)
      @reference_date = reference_date
      @group = group
      @relevant_role_types = (relevant_role_types || SacCas::MITGLIED_ROLES).map(&:sti_name)
    end

    def roles
      group ? active_roles.where(group_id: group.id) : active_roles
    end

    private

    def active_roles
      Role.active(reference_date).where(type: relevant_role_types)
    end
  end
end
