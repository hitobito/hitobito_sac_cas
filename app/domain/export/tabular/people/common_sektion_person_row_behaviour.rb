#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  module CommonSektionPersonRowBehaviour
    def initialize(entry, group, format = nil)
      @group = group
      super(entry, format)
    end

    def url
      Rails.application.routes.url_helpers.history_group_person_url(
        group_id: @group.id,
        id: entry.id,
        host: ActionMailer::Base.default_url_options[:host]
      )
    end

    def sektion
      @group.layer_group.to_s
    end

    def sac_entry_on
      roles(*SacCas::MITGLIED_ROLES).map(&:start_on).min
    end

    def sektion_entry_on
      roles_in_group(*SacCas::MITGLIED_ROLES).map(&:start_on).min
    end

    def terminate_on
      membership_role.terminated_on
    end

    def type
      role_type = membership_role.class.name.demodulize.underscore
      I18n.t("export/tabular/people.attributes.types.#{role_type}")
    end

    def beitragskategorie
      I18n.t("roles.beitragskategorie.#{membership_role.beitragskategorie}")
    end

    def ehrenmitglied
      yes_or_no(active_role_in_group?(Group::SektionsMitglieder::Ehrenmitglied))
    end

    def beguenstigt
      yes_or_no(active_role_in_group?(Group::SektionsMitglieder::Beguenstigt))
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
      entry.roles_unscoped.select { |role| role_classes.include?(role.class) }.sort_by(&:start_on)
    end

    def roles_in_group(*role_classes)
      roles(*role_classes).select { |role| role.group_id == @group.id }
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

    def membership_role
      @membership_role ||= roles_in_group(*SacCas::MITGLIED_ROLES).find do |r|
        @range.cover?(r.start_on)
      end
    end

    def yes_or_no(boolean)
      I18n.t("global.#{boolean ? "yes" : "no"}")
    end
  end
end
