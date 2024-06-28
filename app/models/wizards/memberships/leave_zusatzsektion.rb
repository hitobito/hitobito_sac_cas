# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Memberships
  class LeaveZusatzsektion < Wizards::Base
    self.steps = [
      Wizards::Steps::MembershipTerminatedInfo,
      Wizards::Steps::LeaveZusatzsektion::AskFamilyMainPerson,
      Wizards::Steps::TerminationNoSelfService,
      Wizards::Steps::TerminationChooseDate,
      Wizards::Steps::LeaveZusatzsektion::Summary
    ]

    attr_reader :person, :role

    # TODO: Rename to sektion_name
    def sektion
      role.group.parent.display_name
    end

    def initialize(current_step: 0, person: nil, role: nil, backoffice: false, **params)
      super(current_step: current_step, **params)
      @person = person
      @role = role
      @backoffice = backoffice
    end

    def valid?
      super && leave_operation_valid?
    end

    def save!
      super
      leave_operation.save!
    end

    def leave_operation
      @leave_operation ||= Memberships::LeaveZusatzsektion.new(role, terminate_on)
    end

    def backoffice?
      @backoffice
    end

    def terminate_on
      (step(:termination_choose_date).terminate_on == "now") ? Date.current.yesterday : Date.current.end_of_year
    end

    def mitglied_termination_by_section_only?
      # TODO: Implement
      false
    end

    def sac_mitarbeiter?
      @backoffice
    end

    private

    def family_membership?
      !person.household.empty?
    end

    def family_main_person?
      # TODO: Implement
      false
    end

    def leave_operation_valid?
      return true unless last_step?
      # rubocop:disable Lint/UnreachableCode
      return true

      leave_operation.valid?.tap do
        leave_operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
        leave_operation.errors.copy!(self)
      end
      # rubocop:enable Lint/UnreachableCode
    end

    def step_after(step_class_or_name)
      name = step_class_or_name.is_a?(Class) ? step_class_or_name.step_name : step_class_or_name
      case name
      when :_start
        handle_start
      when Wizards::Steps::MembershipTerminatedInfo.step_name,
        Wizards::Steps::LeaveZusatzsektion::AskFamilyMainPerson.step_name,
        Wizards::Steps::TerminationNoSelfService.step_name
        nil
      else
        super
      end
    end

    def handle_start
      membership_role = Group::SektionsMitglieder::Mitglied.find_by(person: person)
      if membership_role&.terminated?
        Wizards::Steps::MembershipTerminatedInfo.step_name
      elsif mitglied_termination_by_section_only? && !sac_mitarbeiter?
        Wizards::Steps::TerminationNoSelfService.step_name
      elsif family_membership? && !family_main_person?
        Wizards::Steps::LeaveZusatzsektion::AskFamilyMainPerson.step_name
      elsif sac_mitarbeiter?
        Wizards::Steps::TerminationChooseDate.step_name
      else
        Wizards::Steps::LeaveZusatzsektion::Summary.step_name
      end
    end
  end
end
