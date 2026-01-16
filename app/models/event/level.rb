# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_levels
#
#  id          :bigint           not null, primary key
#  code        :integer          not null
#  deleted_at  :datetime
#  description :text(65535)
#  difficulty  :integer          not null
#  label       :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Event::Level < ActiveRecord::Base
  include Paranoia::Globalized

  translates :label, :description

  has_many :kinds, class_name: "Event::Kind", dependent: :restrict_with_error

  validates_by_schema
  validates :label, presence: true

  scope :list, -> { includes(:translations).order(:code) }
  # Returns all entries that are assignable to events.
  # Optionally pass the ids of the entries currently assigned to
  # a specific event, so that they always appear in the dropdown,
  # even if they are soft deleted.
  scope :assignable, ->(ids = []) { without_deleted.or(where(id: ids)) }

  def to_s
    label
  end

  # Soft destroy if kinds exist, otherwise hard destroy
  def destroy
    if kinds.with_deleted.exists?
      delete
    else
      really_destroy!
    end
  end
end
