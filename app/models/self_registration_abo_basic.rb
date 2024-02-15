# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistrationAboBasic < SelfRegistrationAbo
  self.partials = [:abo_issue, :abo_main_person]

  def self.model_name
    ActiveModel::Name.new(SelfRegistrationAbo, nil)
  end

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end
end
