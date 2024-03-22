# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleManagerAbility
  extend ActiveSupport::Concern

  prepended do
    on(PeopleManager) do
      permission(:any).may(:create_manager).none
      permission(:any).may(:create_managed).if_can_change_managed_and_is_adult
    end
  end

  def if_can_change_managed_and_is_adult
    if_can_change_managed &&
      SacCas::Beitragskategorie::Calculator.new(subject.manager).adult?
  end
end
