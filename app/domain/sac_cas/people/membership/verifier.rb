# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::People::Membership::Verifier
  extend ActiveSupport::Concern

  def member?
    @person.sac_membership_active?
  end

  def sac_membership_anytime?
    @person.sac_membership_anytime?
  end
end
