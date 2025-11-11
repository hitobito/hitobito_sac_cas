# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class TerminatedMitgliedRow < Export::Tabular::Row
    attr_reader :group

    def initialize(entry, group, format = nil)
      @group = group
      super(entry, format)
    end

    def sektion
      group.layer_group.to_s
    end

    def sac_is_terminated
      yes_or_no(membership_role.terminated?)
    end

    def sac_is_section_switch
      yes_or_no(Group::SektionsMitglieder::Mitglied.future.where(person: entry).where.not(group: group).present?)
    end

    def terminate_on
      membership_role.terminated_on
    end

    def termination_reason
      membership_role.termination_reason_text
    end

    def data_protection_agreement
      yes_or_no(true)
    end

    def type
      role_type = membership_role.class.name.demodulize.underscore
      I18n.t("export/tabular/people.attributes.types.#{role_type}")
    end

    def beitragskategorie
      I18n.t("roles.beitragskategorie.#{membership_role.beitragskategorie}")
    end

    def sac_entry_on
      roles(*SacCas::MITGLIED_ROLES).map(&:start_on).min
    end

    def sektion_entry_on
      roles_in_group(*SacCas::MITGLIED_ROLES).map(&:start_on).min
    end

    def ehrenmitglied
      yes_or_no(active_role_in_group?(Group::SektionsMitglieder::Ehrenmitglied))
    end

    def beguenstigt
      yes_or_no(active_role_in_group?(Group::SektionsMitglieder::Beguenstigt))
    end

    def birthday
      entry.birthday
    end

    def gender
      entry.gender_label
    end

    def correspondence
      entry.correspondence_label
    end

    def phone_number_landline
      entry.phone_number_landline&.number
    end

    def phone_number_mobile
      entry.phone_number_mobile&.number
    end

    private

    def roles(*role_classes)
      entry.roles_unscoped.select { |role| role_classes.include?(role.class) }
    end

    def roles_in_group(*role_classes)
      roles(*role_classes).select { |role| role.group_id == group.id }
    end

    def active_role_in_group(*role_classes)
      roles_in_group(*role_classes).find(&:active?)
    end

    def active_role_in_group?(*role_classes)
      active_role_in_group(*role_classes).present?
    end

    def membership_role
      @membership_role ||= active_role_in_group(*SacCas::MITGLIED_ROLES)
    end

    def yes_or_no(boolean)
      I18n.t("global.#{boolean ? "yes" : "no"}")
    end
  end
end
