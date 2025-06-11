# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::AbilityDsl::Constraints
  module MatchingRoles
    extend ActiveSupport::Concern

    prepended do
      # Checks if the user and subject have matching roles in the same layer.
      # * `user_role_types` is an array of role types for the user.
      # * `subject_role_types` is an array of role types for the subject.
      # If a role types argument is blank, it will match any role type for that person.
      # This can not be used directly to define a constraint on a permission as it accepts
      # arguments which is not supported by the DSL. Instead define a method that calls this
      # method with the desired role types and use that method in the DSL.
      #
      # Example:
      #
      # def user_is_admin_and_subject_is_member = matching_roles_in_same_layer(
      #   user_role_types: [::Group::Admin],
      #   subject_role_types: [::Group::Mitglied]
      # )
      # on(Person) do
      #  permission(:any).may(:update).user_is_admin_and_subject_is_member
      #
      def matching_roles_in_same_layer(user_role_types: [], subject_role_types: [])
        subject_person = subject.is_a?(Person) ? subject : subject.person
        return unless can_show_person?(subject_person)

        contains_any?(
          layer_ids_where_person_has_role(user, *user_role_types),
          layer_ids_where_person_has_role(subject_person, *subject_role_types)
        )
      end
    end

    private

    # Returns the layer group IDs where the person has any of the specified role types.
    # Call with blank `role_types` to get all layer group IDs for the person.
    def layer_ids_where_person_has_role(person, *role_types)
      return person.layer_group_ids if role_types.blank?

      roles_scope = person.roles.where(type: role_types.map(&:sti_name))
      Group.joins(:roles).merge(roles_scope)
        .select(:layer_group_id).distinct.pluck(:layer_group_id)
    end

    def can_show_person?(person)
      Ability.new(user).can?(:show_full, person)
    end
  end
end
