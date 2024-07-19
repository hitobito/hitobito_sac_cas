# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MembershipVerifyHelper
  def file_locale = %i[de fr it].include?(I18n.locale) ? I18n.locale : :de

  def localized_sponsor_logo_path
    "membership_verify_partner_ad_#{file_locale.downcase}.jpg"
  end

  def localized_sac_sponsors_url
    {
      de: "https://www.sac-cas.ch/de/der-sac/unsere-partner/",
      fr: "https://www.sac-cas.ch/fr/le-cas/nos-partenaires/",
      it: "https://www.sac-cas.ch/it/il-cas/i-nostri-partner/"
    }[file_locale]
  end
end
