# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club.
#  This file is part of hitobito_sac_cas and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonAbility
  extend ActiveSupport::Concern


  prepended do
    on(Person) do
      permission(:read_all_people).may(:read_all_people, :show).everybody
      class_side(:create_households).if_sac_mitarbeiter
    end
  end

  def if_sac_mitarbeiter
    SacCas::SAC_MITARBEITER_ROLES.any? { |r| role_type?(r) }
  end
end
