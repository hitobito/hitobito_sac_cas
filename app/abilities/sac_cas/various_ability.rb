# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::VariousAbility
  extend ActiveSupport::Concern

  included do
    on(HitobitoLogEntry) do
      class_side(:index).if_mitarbeiter_geschaeftsstelle
      permission(:any).may(:show).if_mitarbeiter_geschaeftsstelle
    end

    on(ChangelogEntry) do
      class_side(:index).if_mitarbeiter_geschaeftsstelle
    end
  end

  def if_mitarbeiter_geschaeftsstelle
    role_type?(Group::Geschaeftsstelle::MitarbeiterLesend, Group::Geschaeftsstelle::Mitarbeiter,
      Group::Geschaeftsstelle::Admin)
  end
end
