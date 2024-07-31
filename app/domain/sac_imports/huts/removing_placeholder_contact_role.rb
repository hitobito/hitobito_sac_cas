# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  module RemovingPlaceholderContactRole
    def remove_placeholder_contact_role(person)
      Group::ExterneKontakte::Kontakt
        .where(person: person,
          group: placeholder_contact_group)
        .find_each(&:really_destroy!)
    end

    def placeholder_contact_group
      @contact_role_group ||= Group::ExterneKontakte.find_by(name: "Navision Import",
        parent_id: Group::SacCas.first!.id)
    end
  end
end
