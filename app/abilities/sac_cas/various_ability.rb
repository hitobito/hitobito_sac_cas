# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::VariousAbility
  extend ActiveSupport::Concern

  prepended do
    on(CostCenter) do
      class_side(:index).if_admin
      permission(:admin).may(:manage).all
    end

    on(CostUnit) do
      class_side(:index).if_admin
      permission(:admin).may(:manage).all
    end

    on(Event::Level) do
      class_side(:index).if_admin
      permission(:admin).may(:manage).all
    end
  end
end
