# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::ApprovalCommissionResponsibility < ActiveRecord::Base
  attr_readonly :sektion_id, :target_group_id, :discipline_id, :subito

  belongs_to :sektion, class_name: "Group"
  belongs_to :freigabe_komitee, class_name: "Group"
  belongs_to :target_group
  belongs_to :discipline

  validates :freigabe_komitee, presence: true # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo
  validates :sektion_id, uniqueness: {
    scope: [:target_group_id, :discipline_id, :subito],
    message: I18n.t(
      "activerecord.errors.models.event_approval_commission_responsibility.combination_exists"
    )
  }
  validate :validate_freigabe_komitee_inside_layer, if: :freigabe_komitee
  validate :validate_only_base_target_group, on: :create
  validate :validate_only_base_discipline, on: :create

  private

  def validate_freigabe_komitee_inside_layer
    errors.add(:freigabe_komitee, :not_in_layer) unless freigabe_komitee&.layer_group == sektion
  end

  def validate_only_base_target_group
    errors.add(:target_group, :no_base_target_group) if target_group&.parent.present?
  end

  def validate_only_base_discipline
    errors.add(:discipline, :no_base_discipline) if discipline&.parent.present?
  end
end
