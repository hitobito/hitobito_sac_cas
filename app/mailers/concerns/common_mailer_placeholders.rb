# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module CommonMailerPlaceholders
  def placeholder_first_name
    @person.first_name
  end

  def placeholder_last_name
    @person.last_name
  end

  def placeholder_birthday
    l(@person.birthday)
  end

  def placeholder_email
    @person.email
  end

  def placeholder_phone_number
    @person.phone_numbers.first
  end

  def placeholder_address_care_of
    @person.address_care_of
  end

  def placeholder_street_with_number
    @person.address
  end

  def placeholder_postbox
    @person.postbox
  end

  def placeholder_zip_code
    @person.zip_code
  end

  def placeholder_town
    @person.town
  end

  def placeholder_country
    @person.country
  end

  def placeholder_profile_url
    group_person_url(@person.default_group_id, @person.id)
  end

  def placeholder_faq_url
    t("global.links.faq")
  end
end
