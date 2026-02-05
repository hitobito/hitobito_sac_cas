# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Contactable::Address
  extend ActiveSupport::Concern
  def for_membership_pass
    (contactable_and_company_name + address_with_multilanguage_country).compact.join("\n")
  end

  def address_with_multilanguage_country
    [
      @contactable.address.to_s.strip,
      [@contactable.zip_code, @contactable.town].compact.join(" ").squish,
      country_string(:country_label)
    ]
  end
end
