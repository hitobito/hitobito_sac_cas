# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Memberships
  class TerminateSacMembershipWizard < Wizards::Base
    self.steps = [
      Wizards::Steps::MembershipTerminatedInfo,
      Wizards::Steps::AskFamilyMainPerson,
      Wizards::Steps::TerminationNoSelfService,
      Wizards::Steps::TerminationChooseDate,
      Wizards::Steps::Termination::Summary
    ]

    attr_reader :person

    def initialize(current_step: 0, person: nil, backoffice: nil, **params)
      @person = person
      @backoffice = backoffice
      super(current_step: current_step, **params)
    end

    def valid?
      super && terminate_operation_valid?
    end

    def save!
      super && terminate_operation.save! && send_confirmation_mail
    end

    def terminate_operation
      @terminate_operation ||=
        Memberships::TerminateSacMembership.new(
          role,
          terminate_on,
          backoffice: backoffice?,
          subscribe_newsletter: step(:summary)&.subscribe_newsletter,
          subscribe_fundraising_list: step(:summary)&.subscribe_fundraising_list,
          data_retention_consent: step(:summary)&.data_retention_consent,
          termination_reason_id: step(:summary)&.termination_reason_id
        )
    end

    def terminate_operation_valid?
      return true unless last_step?

      terminate_operation.valid?.tap do
        terminate_operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
      end

      errors.empty?
    end

    def sektion_name
      role&.layer_group&.display_name
    end

    def terminate_on
      if step(:termination_choose_date)&.terminate_on == "now"
        Date.current.yesterday
      else
        Date.current.end_of_year
      end
    end

    def role
      person&.sac_membership&.stammsektion_role
    end

    def mitglied_termination_by_section_only?
      role&.layer_group&.mitglied_termination_by_section_only ||
        person.household.people
          .flat_map { |person| person.sac_membership.zusatzsektion_roles }
          .any? { |role| role.layer_group&.mitglied_termination_by_section_only }
    end

    def family_membership?
      person.sac_membership.family?
    end

    def backoffice?
      @backoffice
    end

    private

    def send_confirmation_mail
      Memberships::TerminateSacMembershipMailer.confirmation(
        person,
        sektion_name,
        I18n.l(terminate_on)
      ).deliver_later
    end

    def family_main_person?
      person.sac_family_main_person
    end

    def step_after(step_class_or_name)
      case step_class_or_name
      when :_start
        handle_start
      when Wizards::Steps::TerminationChooseDate
        Wizards::Steps::Termination::Summary.step_name
      when Wizards::Steps::Termination::Summary
        nil
      end
    end

    def handle_start
      if person.sac_membership.terminated?
        Wizards::Steps::TerminationChooseDate.step_name
      elsif family_membership? && !family_main_person?
        Wizards::Steps::AskFamilyMainPerson.step_name
      elsif mitglied_termination_by_section_only? && !backoffice?
        Wizards::Steps::TerminationNoSelfService.step_name
      elsif backoffice?
        Wizards::Steps::TerminationChooseDate.step_name
      else
        Wizards::Steps::Termination::Summary.step_name
      end
    end
  end
end
