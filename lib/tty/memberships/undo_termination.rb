# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Memberships
    class UndoTermination
      prepend TTY::Command

      self.description = "Undo Termination"

      attr_reader :role, :undo

      def initialize
        @role = ask_for_role
        load_undo
      end

      def run
        undo.save(validate: false) if confirm?
        puts green "Undo completed"
        true
      end

      private

      def ask_for_role
        loop do
          print "Please enter the ID of the membership role you want to restore: "
          role_id = gets.chomp

          unless /\A\d+\z/.match?(role_id)
            puts error "Invalid ID. Please enter a number."
            next # ask again
          end

          membership_role = SacCas::MITGLIED_ROLES.lazy.map do |role_type|
            role_type.with_inactive.find_by(id: role_id)
          end.find(&:itself)

          unless membership_role
            puts error "Membership role #{role_id} not found. Please give me a valid ID."
            next # ask again
          end

          unless membership_role.terminated
            puts error "Membership role #{role_id} is not terminated, nothing to restore."
            next # ask again
          end

          puts "Found #{membership_role.type} in #{membership_role.group.layer_group} for person #{membership_role.person_id} #{membership_role.person}"
          return membership_role
        end
      end

      def confirm?
        puts "Reactivating people and roles: "
        puts
        undo.restored_people.each do |person|
          puts "* #{person} #{person.id}:"
          puts "  #{person.changes.inspect}"
          puts
          undo.restored_roles.select { |r| r.person_id == person.id }.each do |role|
            changes = role.changes.except("updated_at")
            current_state = Role.with_inactive.find(role.id)
            puts "  - #{role.type} #{role.id} in #{role.group.layer_group} > #{role.group}:"
            puts "    current DB values: #{current_state.attributes.slice("start_on", "end_on")}"
            puts "    changes: #{changes.inspect}"
            puts
          end
          puts
        end

        puts red "!!! The undo is invalid !!!" unless undo.valid?
        puts yellow "The mutation_id is missing." unless terminating_version.mutation_id.present?

        CliMenu.new(menu_actions: {
          "y" => {description: "Yes, undo the termination", action: -> {
            puts "Performing undo..."
            true
          }},
          "n" => {description: "No, do not undo the termination", action: -> {
            puts light_red "Undo canceled."
            false
          }},
          "r" => {description: "Revert start_on changes", action: -> {
            revert_start_on
            confirm?
          }, color: :yellow},
          "m" => {description: "Set mutation_id", action: -> {
            set_mutation_id
            reload!
            confirm?
          }, color: :yellow},
          "p" => {description: "Open person history", action: -> {
            open_profile
            confirm?
          }},
          "`" => {description: "Open pry shell", action: -> {
            pry_console
            confirm?
          }, style: :dim}
        }).run
      end

      def load_undo
        @undo = ::Memberships::UndoTermination.new(role)
        nil
      end

      def terminating_version(r = role)
        r.versions.order(id: :desc).find { |v| v.object_changes.include?("terminated:\n- false\n- true") }
      end

      def open_profile
        url = group_person_path(
          host: "portal.sac-cas.ch",
          protocol: "https",
          group_id: person.primary_group_id,
          id: role.person.id
        )
        system("xdg-open", url, out: "/dev/null")
      end

      ## methods used interactively in pry console

      alias_method :reload!, :load_undo

      def revert_start_on
        undo.restored_roles.each do |role|
          next unless role.changes["start_on"]

          role.start_on = role.changes["start_on"].first
        end
        nil
      end

      def set_mutation_id
        return puts(error("This is a family role, manual intervention is required.")) if undo.role.family?
        version = terminating_version
        return puts(warn("Role already has a mutation_id")) if version.mutation_id.present?

        version.update!(mutation_id: SecureRandom.uuid)
      end

      def pry_console
        binding.pry
      end

      def family_roles
        return [] unless role.family_id

        Role.with_inactive.where(family_id: role.family_id, end_on: role.end_on)
      end

      def family_terminating_versions
        family_roles.map do |role|
          terminating_version(role)
        end.then do |versions|
          PaperTrail::Version.where(id: versions.map(&:id))
        end
      end

      def set_family_mutation_id
        return puts(warn("Role already has a mutation_id")) if terminating_version.mutation_id.present?

        family_terminating_versions.update_all(mutation_id: SecureRandom.uuid)
        reload!
      end
    end
  end
end
