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
        @undo = ::Memberships::UndoTermination.new(role)
      end

      def run
        undo.save(validate: false) if confirm?
        puts green "Undo completed"
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
        print yellow "Do you want to execute the undo? (y/n) or open pry to edit (e): "

        loop do
          choice = $stdin.getch.tap { puts } # Read a single character and print a newline

          case choice
          when "y"
            puts "Performing undo..."
            return true
          when "n"
            puts light_red "Undo canceled."
            return false
          when "e"
            puts "Opening pry console to edit the undo..."
            binding.pry
            return confirm?
          else
            puts error "Invalid choice. Please enter 'y' or 'n'."
          end
        end
      end
    end
  end
end
