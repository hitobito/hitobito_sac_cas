# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Memberships
  class LeaveZusatzsektion < Wizards::Base
    self.steps = [
      Wizards::Steps::MembershipTerminatedInfo,
      Wizards::Steps::AskFamilyMainPerson,
      Wizards::Steps::TerminationNoSelfService,
      Wizards::Steps::TerminationChooseDate,
      Wizards::Steps::LeaveZusatzsektion::Summary
    ]

    attr_reader :person, :role

    delegate :name, to: :sektion, prefix: true

    def initialize(person:, role:, current_step: 0, backoffice: false, **params)
      @person = person
      @role = role
      @backoffice = backoffice
      super(current_step: current_step, **params)
    end

    def valid?
      super && leave_operation_valid?
    end

    def save!
      super
      leave_operation.save!.tap { send_confirmation_mail }
    end

    def leave_operation
      @leave_operation ||= Memberships::LeaveZusatzsektion.new(role, terminate_on, termination_reason_id: termination_reason_id)
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

    def termination_reason_id
      step(:summary)&.termination_reason_id
    end

    def mitglied_termination_by_section_only?
      role.layer_group.try(:mitglied_termination_by_section_only)
    end

    def family_membership?
      role.beitragskategorie.family?
    end

    def sektion = role.layer_group

    private

    def send_confirmation_mail
      Memberships::TerminateMembershipMailer.leave_zusatzsektion(
        person,
        sektion,
        I18n.l(terminate_on)
      ).deliver_later
    end

    def family_main_person?
      person.sac_family_main_person
    end

    def leave_operation_valid?
      return true unless last_step?

      leave_operation.valid?.tap do
        leave_operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
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
        Wizards::Steps::AskFamilyMainPerson.step_name
      elsif backoffice?
        Wizards::Steps::TerminationChooseDate.step_name
      else
        Wizards::Steps::LeaveZusatzsektion::Summary.step_name
      end
    end
  end
end
