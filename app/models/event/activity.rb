# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
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

  has_and_belongs_to_many :events, join_table: "events_activities"
  belongs_to :technical_requirement

  validates :description, presence: true
  validates :color, format: {with: /\A#[A-Fa-f0-9]{6}\Z/, message: :invalid_hex_color},
    allow_blank: true
  validates :color, absence: true, unless: :main?
  validates :technical_requirement_id, absence: true, if: :main?
  validate :assert_technical_requirement_is_main

  after_commit :create_approval_commission_responsibilities, if: :main?, on: :create

  def create_approval_commission_responsibilities
    Event::CreateApprovalCommissionResponsibilitiesJob.new(activity: self).enqueue!
  end

  private

  def assert_technical_requirement_is_main
    return unless technical_requirement

    errors.add(:technical_requirement_id, :must_be_main) unless technical_requirement.main?
  end
end
