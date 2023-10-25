# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People
  module Neuanmeldungen

    # Approve Neuanmeldungen
    #
    # In the given group for all People with the given people_ids their Role
    # `Group::SektionsNeuanmeldungenSektion::Neuanmeldung` will be replaced
    # with a Role `Group::SektionsNeuanmeldungenNv::Neuanmeldung`.
    #
    # Example:
    #   People::Neuanmeldungen::Approve.new(group: group, people_ids: people_ids).call
    #
    class Approve < Base

      def call
        applicable_roles.each do |role|
          Role.transaction do
            create_approved_role(role)
            role.destroy!
          end
        end
      end

      private

      def approved_roles_group
        group
          .parent.children.without_deleted
          .find_by(type: APPROVED_NEUANMELDUNGEN_GROUP.sti_name) ||
        APPROVED_NEUANMELDUNGEN_GROUP.create!(parent: group.parent)
      end

      def create_approved_role(role)
        return if approved_roles_group.roles.
                  where(type: APPROVED_NEUANMELDUNGEN_ROLE.sti_name, person_id: role.person_id).
                  exists?

        APPROVED_NEUANMELDUNGEN_ROLE.create!(
          group: approved_roles_group,
          person: role.person,
          beitragskategorie: role.beitragskategorie
        )
      end

    end
  end
end
