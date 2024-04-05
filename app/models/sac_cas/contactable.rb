# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Contactable
  def country_label
    return super if country.present?

    Countries.label('CH')
  end

  def ignored_country?
    false # https://github.com/hitobito/hitobito_sac_cas/issues/426
  end
end
