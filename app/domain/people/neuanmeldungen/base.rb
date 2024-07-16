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

      NEUANMELDUNGEN_ROLES = [
        Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name,
        Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name
      ].freeze
      APPROVED_NEUANMELDUNGEN_ROLE = Group::SektionsNeuanmeldungenNv::Neuanmeldung
      APPROVED_NEUANMELDUNGEN_GROUP = Group::SektionsNeuanmeldungenNv

      def call
        raise NotImplementedError, "Implement this method in subclass"
      end

      def applicable_people_ids
        Person.where(id: people_ids).flat_map { |person| person.household.people }.uniq.pluck(:id)
      end

      private

      def applicable_roles
        group.roles.where(type: NEUANMELDUNGEN_ROLES, person_id: applicable_people_ids)
      end

      def non_applicable_roles
        Role.with_deleted.where(person_id: people_ids).where.not(type: NEUANMELDUNGEN_ROLES)
      end
    end
  end
end
