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

  include CapitalizedDependentErrors

  has_many :event_approval_commission_responsibilities, dependent: :restrict_with_error,
    class_name: "Event::ApprovalCommissionResponsibility"
  has_many :event_approvals, dependent: :restrict_with_error,
    class_name: "Event::Approval"

  after_commit :create_approval_commission_responsibilities, if: :first_in_layer?, on: :create

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

  def create_approval_commission_responsibilities
    Event::CreateApprovalCommissionResponsibilitiesJob.new(freigabe_komitee_group: self).enqueue!
  end

  def first_in_layer?
    groups_in_same_layer.where(type: Group::FreigabeKomitee.sti_name).count == 1
  end
end
