# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_target_groups
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

class Event::TargetGroup < ActiveRecord::Base
  include NestableTourEssential
  include Events::ApprovalCommissionResponsibilityComponents

  has_and_belongs_to_many :events, join_table: "events_target_groups"

  validates :description, presence: true

  after_commit :create_approval_commission_responsibilities, if: :main?, on: :create

  def create_approval_commission_responsibilities
    Event::CreateApprovalCommissionResponsibilitiesJob.new(target_group: self).enqueue!
  end
end
