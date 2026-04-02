# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Approval < ApplicationRecord
  belongs_to :event
  belongs_to :freigabe_komitee, class_name: "Group"
  belongs_to :approval_kind

  belongs_to :creator, class_name: "Person"

  validates :event_id, uniqueness: {scope: [:freigabe_komitee_id, :approval_kind_id]}
  validates :approval_kind, presence: true, if: :freigabe_komitee
end
