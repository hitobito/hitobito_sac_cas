# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("lib", "import", "xlsx_reader.rb")

module SacImports
  module Sektion
    class MembershipsImporter < SacImports::PeopleImporter
      # self.headers = {
      #   navision_id: "Mitgliedernummer",
      #   household_key: "Familien-Nr.",
      #   group_navision_id: "Sektion",
      #   beitragskategorie: "Kategorie",
      #   member_type: "Mitgliederart",
      #   last_joining_date: "Letztes Eintrittsdatum",
      #   last_exit_date: "Letztes Austrittsdatum",
      #   joining_year: "Eintrittsjahr",
      #   ehrenmitglied: "Ehrenmitglied Sektion",
      #   beguenstigt: "Begünstigter Sektion"
      # }.freeze
      #
      # self.sheet_name = "aktive_mitglieder"
      #
      # class_attribute :target_role_type, default: Membership::TARGET_ROLE_TYPE
      #
      # attr_reader :membership_groups, :missing_sections
      #
      # def initialize(path, skip_existing: false, output: $stdout)
      #   super
      #   @membership_groups = ::Group::SektionsMitglieder.includes(:parent)
      #     .select { |group| group.parent.navision_id.present? }
      #     .index_by { |group| group.parent.navision_id.to_i }
      #   @missing_sections = Set.new
      # end
      #
      # private
      #
      # def people_ids_already_having_membership
      #   @people_ids_already_having_membership ||= Set.new(
      #     ::Person.joins(:roles).where(roles: {type: target_role_type.sti_name}).pluck(:id)
      #   )
      # end
      #
      # def skip?(row)
      #   skip_existing && people_ids_already_having_membership.include?(navision_id(row).to_i)
      # end
      #
      # def membership_group(row)
      #   return if row[:group_navision_id].blank?
      #
      #   membership_groups[row[:group_navision_id].to_i] ||
      #     missing_sections << row[:group_navision_id].inspect && return
      # end
      #
      # def import_row(row)
      #   membership = SacImports::Sektion::Membership.new(
      #     row,
      #     group: membership_group(row),
      #     placeholder_contact_group: contact_role_group,
      #     current_ability: root_ability
      #   )
      #
      #   import_membership(membership, row)
      # end
      #
      # def import_membership(membership, row)
      #   if membership.valid?
      #     membership.import!
      #     output.puts "Finished importing #{membership}"
      #   else
      #     errors << membership.errors
      #   end
      # rescue ActiveRecord::RecordInvalid => e
      #   errors << "CAN NOT IMPORT ROW WITH NAVISION ID: #{navision_id(row)}\n#{e.message}"
      # end
      #
      # def print_summary
      #   membership_groups.each_value do |group|
      #     active = target_role_type.where(group_id: group.id).count
      #     deleted = target_role_type.where(group_id: group.id).deleted.count
      #     output.puts(
      #       "#{group.parent} hat #{active} aktive, #{deleted} inaktive Hauptmitgliedschaften"
      #     )
      #   end
      #
      #   output_list("Folgende Sektionen konnten nicht gefunden werden:", missing_sections.to_a)
      # end

      # def root_user
      #   @root_user ||= ::Person.find_by(email: Settings.root_email)
      # end
      #
      # def root_ability
      #   @root_ability ||= Ability.new(root_user)
      # end
    end
  end
end
