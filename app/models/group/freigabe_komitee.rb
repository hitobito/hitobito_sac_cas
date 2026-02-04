# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::FreigabeKomitee < Group
  class Pruefer < ::Role
    has_and_belongs_to_many :approval_kinds,
      class_name: "Event::ApprovalKind",
      join_table: :roles_event_approval_kinds,
      foreign_key: :role_id,
      association_foreign_key: :approval_kind_id

    self.used_attributes += [approval_kind_ids: []]

    self.permissions = [:group_read]
  end

  roles Pruefer
end
