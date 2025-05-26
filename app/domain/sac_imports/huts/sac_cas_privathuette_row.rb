# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class SacCasPrivathuetteRow < HutRow
    self.type = "SacCasPrivathuette"
    self.category = "Privat"
    self.owned_by_geschaeftsstelle = true

    delegate :parent, to: :class

    def self.parent
      @parent ||= Group::SacCasPrivathuetten.find_or_create_by(parent_id: Group.root.id)
    end
  end
end
