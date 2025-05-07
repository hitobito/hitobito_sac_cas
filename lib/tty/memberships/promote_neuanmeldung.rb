# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output

require_relative "../command"

module TTY
  module Memberships
    class PromoteNeuanmeldung
      prepend TTY::Command

      self.description = "Promote Neuanmeldung to Membership #{gray("(Stammsektion or Zusatzsektion)")}"

      attr_reader :neuanmeldung, :end_on

      def initialize
        @neuanmeldung = ask_for_neuanmeldung_role
        @end_on = ask_for_end_on
      end

      def run
        promote if confirm?
        # self.class.new
      end

      private

      def ask_for_neuanmeldung_role
        loop do
          print "Please enter the ID of the Neuanmeldung role you want to promote: "
          neuanmeldung_role_id = gets.chomp

          unless /\A\d+\z/.match?(neuanmeldung_role_id)
            puts error "Invalid ID. Please enter a number."
            next # ask again
          end

          neuanmeldung = SacCas::NEUANMELDUNG_ROLES.lazy.map do |role_type|
            role_type.find_by(id: neuanmeldung_role_id)
          end.find(&:itself)

          unless neuanmeldung
            puts error "Neuanmeldung #{neuanmeldung_role_id} not found. Please give me a valid ID."
            next # ask again
          end

          puts "Found #{neuanmeldung.type} in #{neuanmeldung.group.layer_group} for person #{neuanmeldung.person_id} #{neuanmeldung.person}"
          return neuanmeldung
        end
      end

      # ask for the date formatted as DD.MM.YYYY
      # use default date Date.current.end_of_year if no date is given
      # parse the date and return it, ask again if the date is invalid
      def ask_for_end_on
        default_date = Date.current.end_of_year
        default_date_formatted = default_date.strftime("%d.%m.%Y")
        prompt = "Please enter the end date for the membership (DD.MM.YYYY) or leave empty for default (#{default_date_formatted}): "

        loop do
          print prompt
          end_on_input = gets.chomp

          if end_on_input.empty?
            puts "Using default end date: #{default_date}"
            return default_date
          end

          begin
            return Date.strptime(end_on_input, "%d.%m.%Y")
          rescue ArgumentError
            puts error "Invalid date format. Please enter a valid date (DD.MM.YYYY)."
          end
        end
      end

      def mitglied_role_type
        @mitglied_role_type ||= /Zusatzsektion/.match?(neuanmeldung.class.name) ?
                               Group::SektionsMitglieder::MitgliedZusatzsektion :
                               Group::SektionsMitglieder::Mitglied
      end

      def mitglied_group
        @mitglied_group ||= neuanmeldung.group.layer_group.children.find_by(type: Group::SektionsMitglieder.sti_name)
      end

      def people_to_promote
        @people_to_promote ||= if neuanmeldung.family?
          neuanmeldung.person.household.people
        else
          [neuanmeldung.person]
        end
      end

      def promote
        Person.transaction do
          people_to_promote.each do |person|
            promote_person(person)
          end
        end
        puts light_green "Promotion completed."
      end

      def promote_person(person)
        puts " -> Promoting #{person.id} #{person} to #{mitglied_role_type.sti_name}"
        start_on = [Date.current, end_on].min

        # Clear the Neuanmeldung role first
        person.roles.where(type: neuanmeldung.class.sti_name, group_id: neuanmeldung.group_id).destroy_all

        # Create the new Mitglied role
        mitglied_role_type.create!(
          person: person,
          group: mitglied_group,
          start_on:,
          end_on:
        )
      end

      def confirm?
        if neuanmeldung.family?
          puts "This is a family Neuanmeldung with the following members:"
          people_to_promote.each { |person| puts "  * #{person.id} #{person}" }
          puts
        end

        print "Do you want to execute the promotion? (y/n): "

        loop do
          choice = $stdin.getch.tap { puts } # Read a single character and print a newline

          case choice
          when "y"
            puts "Starting promotion..."
            return true
          when "n"
            puts light_red "Promotion canceled."
            return false
          else
            puts error "Invalid choice. Please enter 'y' or 'n'."
          end
        end
      end
    end
  end
end

# rubocop:enable Rails/Output
