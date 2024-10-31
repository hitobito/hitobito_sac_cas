# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfInscriptionController
  extend ActiveSupport::Concern

  def create
    if person.years < 6
      redirect_to group_self_inscription_path(group), alert: I18n.t("groups.self_inscription.must_be_six_years_old")
    else
      super
    end
  end
end
