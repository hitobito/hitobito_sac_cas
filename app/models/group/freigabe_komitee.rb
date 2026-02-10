# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::FreigabeKomitee < Group
  # This is necessary since FreigabeKomitee is indirectly referenced and loaded by
  # the SacCas module by being a child of SektionsTourenUndKurse.
  # That reference makes it so the FreigabeKomitee class gets loaded before the SacPhoneNumbers
  # has been prepended on the parent class Group and thus the associations provided by
  # SacPhoneNumbers end up missing.
  prepend SacPhoneNumbers

  has_many :event_approval_commission_responsiblities, dependent: :destroy,
    class_name: "Event::ApprovalCommissionResponsibility"

  def destroy
    if event_approval_commission_responsiblities.present?
      errors.add(:base, :has_event_approval_commission_responsiblities)
    else
      super
    end
  end

  class Pruefer < ::Role
    has_and_belongs_to_many :approval_kinds,
      class_name: "Event::ApprovalKind",
      join_table: :roles_event_approval_kinds,
      foreign_key: :role_id,
      association_foreign_key: :approval_kind_id

    self.used_attributes += [approval_kind_ids: []]

    self.permissions = [:group_read]

    def to_s(format = :default)
      super.then do
        approval_kinds.present? ? "#{_1} (#{approval_kinds.join(", ")})" : _1
      end
    end
  end

  roles Pruefer
end
