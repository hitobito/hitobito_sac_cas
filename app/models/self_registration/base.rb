# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::Base < SelfRegistration

  class_attribute :main_person_class, default: SelfRegistration::MainPerson::Base

  self.partials = [:main_email, :emailless_main_person]


  def main_person
    @main_person ||= build_person(@main_person_attributes, main_person_class)
  end

  private

  def main_email_valid?
    main_person.email.present?
  end

  alias_method :emailless_main_person_valid?, :main_person_valid?
end
