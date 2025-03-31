# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output

require_relative "../helpers/format"

module TTY
  module Memberships
    class PromoteNeuanmeldung
      include TTY::Helpers::Format

      attr_reader :neuanmeldung

      def initialize
        puts light_yellow "Promote Neuanmeldung to Membership"
        @neuanmeldung = ask_for_neuanmeldung_role
      end

      def run
        promote if confirm?
      end

      private

      def ask_for_neuanmeldung_role
        print "Please enter the ID of the Neuanmeldung role you want to promote: "
        neuanmeldung_role_id = gets.chomp

        unless /\A\d+\z/.match?(neuanmeldung_role_id)
          puts error "Invalid ID. Please enter a number."
          return ask_for_neuanmeldung_role
        end

        neuanmeldung = SacCas::NEUANMELDUNG_ROLES.lazy.map do |role_type|
          role_type.find_by(id: neuanmeldung_role_id)
        end.find(&:itself)

        unless neuanmeldung
          puts error "Neuanmeldung #{neuanmeldung_role_id} not found. Please give me a valid ID."
          return ask_for_neuanmeldung_role
        end

        puts "Found #{neuanmeldung.type} in #{neuanmeldung.group.layer_group} for person #{neuanmeldung.person_id} #{neuanmeldung.person}"
        neuanmeldung
      end

      def mitglied_role_type
        @mitglied_role_type ||= /Zusatzsektion/.match?(neuanmeldung.class.name) ?
                               Group::SektionsMitglieder::MitgliedZusatzsektion :
                               Group::SektionsMitglieder::Mitglied
      end

      def mitglied_group
        @mitglied_group ||= neuanmeldung.group.layer_group.children.find_by(type: Group::SektionsMitglieder.sti_name)
      end

      def people
        @people ||= if neuanmeldung.family?
          neuanmeldung.person.household.people
        else
          [neuanmeldung.person]
        end
      end

      def promote
        Person.transaction do
          people.each do |person|
            promote_person(person)
          end
        end
        puts light_green "Promotion completed."
      end

      def promote_person(person)
        puts "Promoting #{person.id} #{person} to Mitglied"
        person.roles.where(type: neuanmeldung.class.sti_name, group_id: neuanmeldung.group_id).destroy_all
        mitglied_role_type.create!(
          person: person,
          group: mitglied_group,
          start_on: Date.current,
          end_on: Date.current.end_of_year
        )
      end

      def confirm?
        if neuanmeldung.family?
          puts "This is a family Neuanmeldung with the following members:"
          people.each { |person| puts "  * #{person.id} #{person}" }
          puts
        end

        print "Do you want to execute the promotion? (y/n): "
        choice = STDIN.getch

        case choice
        when "y"
          puts "Starting promotion..."
          true
        when "n"
          puts light_red "Promotion canceled."
          false
        else
          puts error "Invalid choice. Please enter 'y' or 'n'."
          confirm?
        end
      end
    end
  end
end

# rubocop:enable Rails/Output
