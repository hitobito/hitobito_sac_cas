# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module NestableTourEssential
  extend ActiveSupport::Concern

  include Paranoia::Globalized

  included do
    attr_readonly :parent_id

    translates :label, :description, :short_description

    belongs_to :parent, optional: true, class_name: name
    has_many :children,
      class_name: name,
      foreign_key: :parent_id,
      inverse_of: :parent,
      dependent: :restrict_with_error

    validates_by_schema
    validates :label, presence: true, uniqueness: {scope: :parent_id}
    validate :assert_parent_is_main

    scope :list, -> { includes(:translations).order(:order) }
    scope :main, -> { where(parent_id: nil) }
    # Returns all entries that are assignable to events.
    # Optionally pass the ids of the entries currently assigned to
    # a specific event, so that they always appear in the dropdown,
    # even if they are soft deleted.
    scope :assignable, (lambda do |ids = []|
      without_deleted
        .or(where(id: ids))
        .or(where(id: where(id: ids).select(:parent_id)))
    end)
  end

  def to_s
    label
  end

  def main?
    parent_id.nil?
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if children.without_deleted.exists?
      errors.add(:base, :has_children)
      false
    elsif events.exists? || children.with_deleted.exists?
      delete
    else
      really_destroy!
    end
  end

  private

  def assert_parent_is_main
    errors.add(:parent_id, :parent_is_not_main) if parent&.parent_id
  end
end
