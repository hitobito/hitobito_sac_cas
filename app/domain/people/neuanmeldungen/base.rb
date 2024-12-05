# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People::Neuanmeldungen
  class Base
    include ActiveModel::Model

    attr_accessor :group, :people_ids

    NEUANMELDUNGEN_ROLES = [
      Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
      Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion
    ].freeze
    APPROVED_NEUANMELDUNGEN_GROUP = Group::SektionsNeuanmeldungenNv

    def call
      raise NotImplementedError, "Implement this method in subclass"
    end

    def applicable_people
      @applicable_people ||= Person.order_by_name.where(id: people_ids).includes(:roles).select("*").flat_map do |person|
        if family_neuanmeldungs_role?(person)
          person.household.people
        else
          person
        end
      end.uniq
    end

    def paying_person?(role)
      role.person.sac_membership.paying_person?(role.beitragskategorie)
    end

    private

    def family_neuanmeldungs_role?(person)
      person.roles.where(type: NEUANMELDUNGEN_ROLES.map(&:sti_name), group: group).family.any?
    end

    def approved_neuanmeldungen_role(role)
      role_type = role.class.to_s.demodulize
      APPROVED_NEUANMELDUNGEN_GROUP.const_get(role_type)
    end

    def applicable_roles
      group.roles.where(type: NEUANMELDUNGEN_ROLES.map(&:sti_name), person: applicable_people)
    end

    def non_applicable_roles
      Role.with_inactive.where(person_id: people_ids).where.not(type: NEUANMELDUNGEN_ROLES.map(&:sti_name))
    end
  end
end
