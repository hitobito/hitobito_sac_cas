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

    def sektion_name
      role.layer_group.display_name
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
      # TODO: Add termination_reason_id https://github.com/hitobito/hitobito_sac_cas/issues/718
      @leave_operation ||= Memberships::LeaveZusatzsektion.new(role, terminate_on)
    end

    def backoffice?
      @backoffice
    end

    def terminate_on
      if step(:termination_choose_date)&.terminate_on == "now"
        Date.current.yesterday
      else
        Date.current.end_of_year
      end
    end

    def mitglied_termination_by_section_only?
      role.layer_group.mitglied_termination_by_section_only
    end

    def family_membership?
      role.beitragskategorie.family?
    end

    private

    def family_main_person?
      person.sac_family_main_person
    end

    def leave_operation_valid?
      return true unless last_step?

      leave_operation.valid?.tap do
        leave_operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
        leave_operation.errors.copy!(self)
      end
    end

    def step_after(step_class_or_name)
      case step_class_or_name
      when :_start
        handle_start
      when Wizards::Steps::TerminationChooseDate
        Wizards::Steps::LeaveZusatzsektion::Summary.step_name
      end
    end

    def handle_start
      if person.sac_membership.terminated?
        Wizards::Steps::MembershipTerminatedInfo.step_name
      elsif mitglied_termination_by_section_only? && !backoffice?
        Wizards::Steps::TerminationNoSelfService.step_name
      elsif family_membership? && !family_main_person?
        Wizards::Steps::LeaveZusatzsektion::AskFamilyMainPerson.step_name
      elsif backoffice?
        Wizards::Steps::TerminationChooseDate.step_name
      else
        Wizards::Steps::LeaveZusatzsektion::Summary.step_name
      end
    end
  end
end
