# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Memberships
  class SwitchStammsektion < Wizards::Base
    self.steps = [
      Wizards::Steps::MembershipTerminatedInfo,
      Wizards::Steps::AskFamilyMainPerson,
      Wizards::Steps::SwitchStammsektion::ChooseSektion,
      Wizards::Steps::SwitchStammsektion::ChooseDate,
      Wizards::Steps::SwitchStammsektion::Summary
    ]

    attr_reader :person

    def initialize(current_step: 0, person: nil, backoffice: false, **params)
      super(current_step: current_step, **params)
      @person = person
      @backoffice = backoffice
    end

    def valid?
      super && switch_operation_valid?
    end

    def save!
      super

      switch_operation.save!.tap do
        send_confirmation_mail
      end
    end

    def switch_operation
      @switch_operation ||=
        Memberships::SwitchStammsektion.new(
          choose_sektion.group,
          person,
          choose_date.switch_date
        )
    end

    def backoffice?
      @backoffice
    end

    private

    def send_confirmation_mail
      Memberships::SwitchStammsektionMailer.confirmation(
        person,
        choose_sektion.group,
        choose_date.switch_on_text
      ).deliver_later
    end

    def switch_operation_valid?
      return true unless last_step?

      switch_operation.valid?.tap do
        switch_operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
      end
    end

    def step_after(step_class_or_name)
      case step_class_or_name
      when :_start
        handle_start
      when Wizards::Steps::MembershipTerminatedInfo, Wizards::Steps::AskFamilyMainPerson
        nil
      else
        super
      end
    end

    def handle_start
      membership_role = Group::SektionsMitglieder::Mitglied.find_by(person: person)
      if membership_role&.terminated?
        Wizards::Steps::MembershipTerminatedInfo.step_name
      elsif person.sac_membership_family? && !(person.sac_family_main_person? || backoffice?)
        Wizards::Steps::AskFamilyMainPerson.step_name
      else
        Wizards::Steps::SwitchStammsektion::ChooseSektion.step_name
      end
    end
  end
end