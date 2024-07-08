# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
module SacCas::Person::Address
  extend ActiveSupport::Concern
  def for_membership_pass
    (person_and_company_name + address_with_multilanguage_country).compact.join("\n")
  end

  def address_with_multilanguage_country
    [
      @person.address.to_s.strip,
      [@person.zip_code, @person.town].compact.join(" ").squish,
      Country.new(country).name
    ]
  end
end
