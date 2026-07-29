# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter::Tour
  class LeaderBase < Events::Filter::Base
    self.permitted_args = [:active]

    class_attribute :role_types

    def apply(scope)
      return scope unless active? && Auth.current_person

      scope
        .joins(participations: :roles)
        .where(
          event_participations: {
            active: true,
            participant_id: Auth.current_person.id,
            participant_type: "Person"
          },
          event_roles: {type: role_types.map(&:sti_name)}
        )
    end

    def blank?
      !active? || Auth.current_person.nil? || role_types.blank?
    end

    private

    def active?
      args[:active].to_s == "1"
    end
  end
end
