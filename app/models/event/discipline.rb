# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_disciplines
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

class Event::Discipline < ActiveRecord::Base
  include NestableTourEssential
  include Events::ApprovalCommissionResponsibilityComponents

  has_and_belongs_to_many :events, join_table: "events_disciplines"

  validates :description, presence: true
  validates :color, format: {with: /\A#[A-Fa-f0-9]{6}\Z/, message: :invalid_hex_color},
    allow_blank: true
end
