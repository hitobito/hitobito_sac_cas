# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Memberships
  class JoinZusatzsektion < Wizards::Base
    self.steps = [
      Wizards::Steps::MembershipTerminatedInfo,
      Wizards::Steps::ChooseMembership,
      Wizards::Steps::ChooseSektionUnrestricted,
      Wizards::Steps::JoinZusatzsektion::Summary
    ]

    attr_reader :person

    def initialize(current_step: 0, person: nil, backoffice: false, **params)
      super(current_step: current_step, **params)
      @person = person
      @backoffice = backoffice
    end

    def valid?
      super && join_operation_valid?
    end

    def save!
      super

      join_operation.save!
    end

    def human_role_type
      beitragskategorie = join_operation.roles.first.beitragskategorie
      I18n.t("invoices.sac_memberships.beitragskategorie.#{beitragskategorie}")
    end

    def join_operation
      @join_operation ||=
        Memberships::JoinZusatzsektion.new(
          choose_sektion.group,
          person,
          Time.zone.today,
          sac_family_membership: family_membership?
        )
    end

    def backoffice?
      @backoffice
    end

    private

    def family_membership?
      choose_membership.register_as_family? if respond_to?(:choose_membership)
    end

    def join_operation_valid?
      return true unless last_step?

      join_operation.valid?.tap do
        join_operation.errors.full_messages.each do |msg|
          errors.add(:base, msg)
        end
      end
    end

    def step_after(step_class_or_name)
      case step_class_or_name
      when :_start
        handle_start
      when Wizards::Steps::MembershipTerminatedInfo
        nil
      else
        super
      end
    end

    def handle_start
      membership_role = Group::SektionsMitglieder::Mitglied.find_by(person: person)
      if membership_role&.terminated?
        Wizards::Steps::MembershipTerminatedInfo.step_name
      elsif person.household.empty?
        Wizards::Steps::ChooseSektionUnrestricted.step_name
      else
        Wizards::Steps::ChooseMembership.step_name
      end
    end
  end
end
