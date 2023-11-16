# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistrations::HouseholdComponent < Groups::SelfRegistrations::BaseComponent

  def next_button_label
    key = entry.housemates.empty? ? 'next_as_single_link' : 'next_as_household_link'
    t("sac_cas.groups.self_registration.household.#{key}")
  end

  def self.title
    I18n.t("sac_cas.groups.self_registration.form.household_title")
  end

  def self.valid?(entry)
    entry.housemates.all? { |housemate| housemate.valid? }
  end

end
