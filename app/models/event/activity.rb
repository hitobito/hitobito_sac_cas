# frozen_string_literal: true

#  Copyright (c) 2025-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_activities
#
#  id                :bigint           not null, primary key
#  order             :integer          not null, default 0
#  parent_id         :bigint
#  label             :string(255)
#  short_description :string(255)
#  description       :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#

class Event::Activity < ActiveRecord::Base
  include NestableTourEssential
  include Events::ApprovalCommissionResponsibilityComponents

  SVG_CONTENT_TYPE = "image/svg+xml"
  ICON_CONTENT_TYPES = [SVG_CONTENT_TYPE, "image/gif", "image/jpeg", "image/png"].freeze

  # Store icons at twice the size displayed so it stays sharp on high resolution displays.
  ICON_SIZE = 32
  ICON_SVG_MAX_BYTES = 100.kilobytes

  has_and_belongs_to_many :events, join_table: "events_activities"
  belongs_to :technical_requirement

  has_one_attached :icon do |attachable|
    attachable.variant :agenda, resize_to_limit: [ICON_SIZE, ICON_SIZE], preprocessed: true
  end

  validates :description, presence: true
  validates :color, format: {with: /\A#[A-Fa-f0-9]{6}\Z/, message: :invalid_hex_color},
    allow_blank: true
  validates :color, absence: true, unless: :main?
  validates :icon, content_type: ICON_CONTENT_TYPES
  validates :icon, size: {less_than: ICON_SVG_MAX_BYTES}, if: :icon_svg?
  validates :icon, absence: true, unless: :main?
  validates :technical_requirement_id, absence: true, if: :main?
  validate :assert_technical_requirement_is_main

  after_commit :create_approval_commission_responsibilities, if: :main?, on: :create

  def create_approval_commission_responsibilities
    Event::CreateApprovalCommissionResponsibilitiesJob.new(activity: self).enqueue!
  end

  def icon_svg?
    icon.attached? && icon.blob.content_type == SVG_CONTENT_TYPE
  end

  def icon_svg(**attributes)
    return unless icon_svg?

    blob = icon.blob
    Rails.cache.fetch(["event_activity_icon_svg", blob.key, attributes]) do
      SanitizedSvg.new(blob.download).to_svg(**attributes)
    end&.html_safe # rubocop:disable Rails/OutputSafety sanitized by SanitizedSvg
  end

  def remove_icon
    false
  end

  def remove_icon=(deletion_param)
    if %w[1 yes true].include?(deletion_param.to_s.downcase) && icon.persisted?
      icon.purge_later
    end
  end

  private

  def assert_technical_requirement_is_main
    return unless technical_requirement

    errors.add(:technical_requirement_id, :must_be_main) unless technical_requirement.main?
  end
end
