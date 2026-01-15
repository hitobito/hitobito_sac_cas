# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_traits
#
#  id                :bigint           not null, primary key
#  order             :integer
#  parent_id         :bigint
#  label             :string(255)
#  short_description :string(255)
#  description       :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#

class Event::Trait < ActiveRecord::Base
  include Paranoia::Globalized

  translates :label, :description, :short_description

  attr_readonly :parent_id

  belongs_to :parent, optional: true, class_name: "Event::Trait"
  has_many :children,
    class_name: "Event::Trait",
    foreign_key: :parent_id,
    inverse_of: :parent,
    dependent: :restrict_with_error
  has_and_belongs_to_many :events, join_table: "events_traits"

  validates_by_schema
  validates :label, presence: true
  validate :assert_parent_is_main

  scope :list, -> { includes(:translations).order(:order) }
  scope :main, -> { where(parent_id: nil) }

  def to_s
    label
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
