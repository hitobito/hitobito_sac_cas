# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::MailRelay::AddressList
  private

  def compose_people_emails
    people_emails = super
    without_emails = people_emails.select { |_, emails| emails.empty? }.keys
    people_emails.merge(managers_emails(without_emails))
  end

  def managers_emails(manageds)
    return {} if manageds.empty?

    managers = load_additional_managers(manageds)
    @manager_ids = managers.map(&:id).to_set
    managers.index_with { |manager| emails_for(manager) }
  end

  def load_additional_managers(manageds)
    person_ids = people.map(&:id).to_set
    Person.joins(:people_manageds)
      .where(people_manageds: {managed_id: manageds.map(&:id)})
      .distinct
      .includes(additional_emails: :category)
      .reject { |manager| person_ids.include?(manager.id) }
  end

  def additional_emails(person)
    return person.additional_emails if @manager_ids&.include?(person.id)

    super
  end
end
