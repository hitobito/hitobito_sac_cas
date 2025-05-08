# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class RoleRow < Row
    class_attribute :code
    class_attribute :role
    class_attribute :role_label

    HUT_CATEGORIES = [
      "SAC Clubhütte",
      "SAC Sektionshütte",
      "Privat"
    ]

    def can_process?
      row[:verteilercode] == code && role_type.present?
    end

    def import!
      unless group
        # TODO fix bugs in data export, where not all huts are exported
        #   and some hut chiefs belong to things other than huts
        output.puts "Skipping #{role} for unknown hut #{contact_navision_id}"
        csv_report.log("Skipping #{role} for unknown hut #{contact_navision_id}")
        return
      end

      yield if block_given?
      destroy_role
      create_role
      person.save!
    end

    def role_type
      @role_type ||= group.class.const_get(role) if HUT_CATEGORIES.include?(row[:hut_category])
    end

    private

    def destroy_role
      person.roles.where(
        type: role_type.name,
        group_id: group.id
      ).destroy_all
    end

    def create_role
      person.roles.build(
        type: role_type.name,
        group_id: group.id,
        label: translated_role_label,
        created_at: row[:created_at]
      )
    end

    def person
      @person ||= Person.find_or_initialize_by(id: related_navision_id) do |p|
        p.first_name = row[:related_first_name]
        p.last_name = row[:related_last_name]
      end.tap(&:save!)
    end

    def group
      @group ||= Group.find_by(navision_id: contact_navision_id)
    end

    def translated_role_label
      if role_label
        sektion = group.parent.parent.parent
        locale = sektion.try(:language)&.downcase || I18n.locale
        I18n.t("activerecord.models.#{role_type.model_name.i18n_key}.#{role_label}", locale: locale)
      end
    end
  end
end
