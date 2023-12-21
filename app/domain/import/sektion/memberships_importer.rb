# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')

module Import
  module Sektion
    class MembershipsImporter < Import::PeopleImporter

      self.headers = {
        navision_id: 'Mitgliedernummer',
        household_key: 'Familien-Nr.',
        first_name: 'Vorname',
        last_name: 'Nachname',
        address_supplement: 'Adresszusatz',
        address: 'Adresse',
        country: 'Länder-/Regionscode',
        town: 'Ort',
        zip_code: 'PLZ',
        email: 'E-Mail',
        postfach: 'Postfach',
        phone: 'Telefon',
        phone_direct: 'Telefon direkt',
        phone_mobile: 'Mobiltelefon',
        birthday: 'Geburtsdatum',
        gender: 'Geschlecht',
        group_navision_id: 'Sektion',
        beitragskategorie: 'Kategorie',
        member_type: 'Mitgliederart',
        language: 'Sprachcode',
        last_joining_date: 'Letztes Eintrittsdatum',
        last_exit_date: 'Letztes Austrittsdatum',
        joining_year: 'Eintrittsjahr'
      }.freeze

      self.sheet_name = 'aktive_mitglieder'

      attr_reader :membership_groups, :missing_sections

      def initialize(path, output: STDOUT)
        super
        @membership_groups = ::Group::SektionsMitglieder.includes(:parent).
          select {|group| group.parent.navision_id.present? }.
          index_by {|group| group.parent.navision_id.to_i }
        @missing_sections = Set.new
      end

      private

      def import_row(row)
        section_id = row[:group_navision_id].to_i

        # we can't import if we can't find the section
        membership_group = membership_groups[section_id] ||
          missing_sections << section_id && return

        membership = ::Import::Sektion::Membership.new(
          row,
          group: membership_group,
          placeholder_contact_group: contact_role_group,
          current_ability: root_ability
        )

        import_person(membership)
      end

      def import_person(membership)
        if membership.valid?
          membership.import!
          output.puts "Finished importing #{membership}"
        else
          errors << membership.errors
        end
      rescue ActiveRecord::RecordInvalid => e
        errors << "CAN NOT IMPORT ROW WITH NAVISION ID: #{row[:navision_id]}\n#{e.message}"
      end

      def print_summary
        membership_groups.each_value do |group|
          active = group.roles.count
          deleted = group.roles.deleted.count
          output.puts "#{group.parent} hat #{active} aktive, #{deleted} inaktive Rollen"
        end

        output_list("Folgende Sektionen konnten nicht gefunden werden:", missing_sections.to_a)
      end

      def root_user
        @root_user ||= ::Person.find_by(email: Settings.root_email)
      end

      def root_ability
        @root_ability ||= Ability.new(root_user)
      end
    end
  end
end
