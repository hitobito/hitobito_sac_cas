# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::Abacus::TransmitPersonJob < BaseJob
  self.parameters = [:person_id]

  def initialize(person)
    super()
    @person_id = person.id
  end

  def perform
    return if person.nil? # may have been deleted already

    subject = Invoices::Abacus::Subject.new(person)
    Invoices::Abacus::SubjectInterface.new.transmit(subject)
  end

  def error(_job, exception)
    HitobitoLogEntry.create!(
      category: :rechnungen,
      level: :error,
      message: "Die Personendaten konnten nicht an Abacus übermittelt werden",
      payload: exception.message,
      subject: person
    )
    super
  end

  private

  def person
    @person ||= Person.find_by(id: @person_id)
  end
end
