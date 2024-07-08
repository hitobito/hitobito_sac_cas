# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People
  module Neuanmeldungen
    class Base
      include ActiveModel::Model

      attr_accessor :group, :people_ids

      NEUANMELDUNGEN_ROLE = Group::SektionsNeuanmeldungenSektion::Neuanmeldung
      APPROVED_NEUANMELDUNGEN_ROLE = Group::SektionsNeuanmeldungenNv::Neuanmeldung
      APPROVED_NEUANMELDUNGEN_GROUP = Group::SektionsNeuanmeldungenNv

      def call
        raise NotImplementedError, "Implement this method in subclass"
      end

      private

      def applicable_roles
        group.roles.where(type: NEUANMELDUNGEN_ROLE.sti_name, person_id: people_ids)
      end

      def non_applicable_roles
        Role.with_deleted.where(person_id: people_ids).where.not(type: NEUANMELDUNGEN_ROLE.sti_name)
      end
    end
  end
end
