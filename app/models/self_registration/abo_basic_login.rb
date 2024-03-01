# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::AboBasicLogin < SelfRegistration

  self.partials = [:main_email, :emailless_main_person]

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end

  private

  def main_email_valid?
    main_person.email.present?
  end

  alias_method :emailless_main_person_valid?, :main_person_valid?
end
