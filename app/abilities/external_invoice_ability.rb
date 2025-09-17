# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalInvoiceAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(ExternalInvoice) do
    permission(:layer_and_below_full).may(:manage).if_backoffice
  end

  def person
    subject.person
  end

  def if_backoffice
    role_type?(*SacCas::SAC_BACKOFFICE_ROLES)
  end
end
