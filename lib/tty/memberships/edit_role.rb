# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Memberships
    class EditRole
      prepend TTY::Command

      include Rails.application.routes.url_helpers

      self.description = "Edit membership role"

      attr_reader :person, :role

      def initialize
        @person = ask_for_person || return
        puts light_green "Person found: #{person} (#{person.id})"
        puts green "  this person is part of a family: #{affected_people.map { |p| "#{p} (#{p.id})" }.join(", ")}" if family?
        @role = ask_for_role || return
        edit_role
      end

      def run
        save_role! if confirm?
      end

      private

      def family? = person.sac_membership.family?

      def affected_people
        family? ? person.household.people : [person]
      end

      def ask_for_person
        loop do
          print "Please enter the ID of the person: "
          person_id = gets.chomp

          unless /\A\d+\z/.match?(person_id)
            puts error "Invalid ID. Please enter a number."
            next # ask again
          end

          person = Person.find_by(id: person_id)

          unless person
            puts error "Person #{person_id} not found. Please give me a valid ID."
            next # ask again
          end

          return person
        end
      end

      def ask_for_role
        membership_roles = person.roles.with_inactive
          .where(type: SacCas::MITGLIED_ROLES.map(&:sti_name)).order(:type, :start_on)

        options = membership_roles.each_with_index.each_with_object({}) do |(role, index), aggr|
          aggr[index + 1] = role_option(role)
        end
        options["p"] = profile_option { ask_for_role }

        CliMenu.new(prompt: "Choose the role to edit", menu_actions: options).run
      end

      def role_option(role)
        {
          description: "#{I18n.l(role.start_on)}-#{I18n.l(role.end_on)} #{role.class.name.demodulize} in #{role.group.layer_group}",
          action: role,
          style: role.is_a?(Group::SektionsMitglieder::Mitglied) ? :green : :yellow
        }
      end

      def profile_option
        {
          description: "Open person profile in browser",
          action: -> {
            open_person_history
            yield if block_given?
          },
          style: :dim
        }
      end

      def edit_role
        puts "Editing role #{role.id} of type #{role.class.name} in group #{role.group.layer_group}"
        binding.pry
      end

      def save_role!
        puts "Saving changes to role #{role.id}..."
        role.save!
        puts green "Role #{role.id} saved successfully."
      rescue StandardError => e
        puts error "Failed to save role: #{e.message}"
      end

      def confirm?
        puts "Do you want to save the following changes to the role?"
        role.changes.each do |attribute, values|
          puts "  * #{attribute}: #{values.first} -> #{values.last}"
        end

        CliMenu.new(
          menu_actions: {
            "y" => {description: "Yes, save changes", action: -> { true }},
            "n" => {description: "No, cancel", action: -> { false }},
            "p" => {description: "Open person profile in browser", action: -> {
              open_person_history
              confirm?
            }, style: :dim}
          }
        ).run
      end

      def open_person_history
        url = history_group_person_url(
          host: "portal.sac-cas.ch",
          protocol: "https",
          group_id: Group.root.id,
          id: person
        )
        system("xdg-open", url, out: "/dev/null")
      end
    end
  end
end
