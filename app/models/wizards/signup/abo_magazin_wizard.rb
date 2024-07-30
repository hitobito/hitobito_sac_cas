# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class AboMagazinWizard < Wizards::RegisterNewUserWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::AboMagazin::PersonFields,
      Wizards::Steps::Signup::AboMagazin::IssuesFromField
    ]

    public :group

    delegate :email, to: :main_email_field

    def save!
      super
      exclude_from_mailing_list unless person_fields.newsletter
    end

    def costs = [
      OpenStruct.new(amount: 60, country: :switzerland),
      OpenStruct.new(amount: 76, country: :international)
    ]

    def requires_policy_acceptance? = false

    private

    def build_person
      super do |_person, role|
        role.delete_on = Time.zone.now.end_of_year.to_date
      end
    end

    def person_attributes
      person_fields
        .person_attributes
        .merge(main_email_field.attributes)
    end

    def exclude_from_mailing_list
      mailing_list = MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
      mailing_list&.subscriptions&.create!(subscriber: person, excluded: true)
    end
  end
end
