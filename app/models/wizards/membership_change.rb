module Wizards
  class MembershipChange < Wizards::RegistrationWizardBase
    self.steps = [
      Steps::ChooseSektion,
      Steps::MembershipChange::ChooseDate,
      Steps::MembershipChange::Summary
    ]

    def step_after(step_class_or_name)
      return super unless step_class_or_name == :start

      sac_mitarbeiter? ? :choose_date : :summary
    end

    def sac_mitarbeiter?
      current_user.roles.any?(Group::Geschaeftsstelle::Mitarbeiter) ||
        current_user.roles.any?(Group::Geschaeftsstelle::Admin)
    end

    def assign_group # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      self.group = step(:choose_sektion).group
    end

    def birthdays
      # TODO: update after ::Household model is implemented
      (current_user.household_people.to_a << current_user).map(&:birthday).compact
    end
  end
end
