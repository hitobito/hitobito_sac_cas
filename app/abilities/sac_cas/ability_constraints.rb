# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::AbilityConstraints
  extend ActiveSupport::Concern

  def unless_sektions_mitgliederverwaltung
    user_context.user.roles.none? { |r| r.is_a?(Group::SektionsFunktionaere::Mitgliederverwaltung) }
  end
end

