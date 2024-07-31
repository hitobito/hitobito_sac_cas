# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class AboBasicLoginWizard < Wizards::RegisterNewUserWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::AboBasicLogin::PersonFields
    ]

    public :group

    delegate :email, to: :main_email_field
    delegate :newsletter, to: :person_fields

    def save!
      super
      exclude_from_mailing_list unless newsletter
    end

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
