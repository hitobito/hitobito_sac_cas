# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::ApprovalKind < ActiveRecord::Base
  include Paranoia::Globalized

  has_and_belongs_to_many :roles, join_table: "roles_event_approval_kinds"

  translates :name, :short_description

  scope :list, -> { includes(:translations).order(:order) }

  validates :name, :order, presence: true
  validates :name, uniqueness: true

  def to_s = name

  # Soft destroy if roles exist, otherwise hard destroy
  def destroy
    if roles.present?
      delete
    else
      really_destroy!
    end
  end
end
