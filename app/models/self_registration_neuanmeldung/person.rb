# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung::Person < SelfRegistration::Person
  attr_accessor :supplements

  delegate :register_on, to: :supplements, allow_nil: true

  include FutureRole::FormHandling

  def role
    @role ||= (register_on_date ? build_future_role : build_role)
  end

  def valid?
    super && person.valid?
  end

  private

  def build_future_role
    FutureRole.new(
      person: person,
      group: primary_group,
      convert_on: register_on_date,
      convert_to: role_type
    )
  end

  def build_role
    Role.new(
      person: person,
      group: primary_group,
      type: role_type,
      created_at: Time.zone.now,
      delete_on: Time.zone.today.end_of_year
    )
  end
end
