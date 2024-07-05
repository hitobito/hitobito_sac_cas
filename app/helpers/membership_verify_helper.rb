# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MembershipVerifyHelper
  def localized_logo_path
    "sac_logo_#{I18n.locale.downcase}.svg"
  end

  def localized_sac_sponsors_url
    {
      de: "https://www.sac-cas.ch/de/der-sac/unsere-partner/",
      fr: "https://www.sac-cas.ch/fr/le-cas/nos-partenaires/",
      it: "https://www.sac-cas.ch/it/il-cas/i-nostri-partner/"
    }[I18n.locale]
  end
end
