# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::KomiteeApproval
  include ActiveModel::Model

  attr_reader :freigabe_komitee, :approval_kinds, :approvals, :disciplines_target_groups,
    :responsible_kinds, :approval_kind_approvals

  def initialize(freigabe_komitee:, approval_kinds:, approvals:, disciplines_target_groups:,
    responsible_kinds:)
    @freigabe_komitee = freigabe_komitee
    @approval_kinds = approval_kinds
    @approvals = approvals
    @disciplines_target_groups = disciplines_target_groups
    @responsible_kinds = responsible_kinds
    @approval_kind_approvals = build_kind_approvals
  end

  def approval_kind_approvals_attributes=(attributes)
    list = attributes.is_a?(Hash) ? attributes.values : attributes
    list.each do |attrs|
      approval_kind_approvals
        .find { |ka| ka.approval_kind_id == attrs[:approval_kind_id].to_i }
        &.assign_attributes(attrs.except(:approval_kind_id))
    end
  end

  def freigabe_komitee_id
    freigabe_komitee.id
  end

  def approvable?
    approval_kind_approvals.any?(&:approvable)
  end

  def all_approved?
    approval_kind_approvals.all?(&:approved)
  end

  def pre_check_approvable
    approval_kind_approvals.each(&:pre_check_approvable)
  end

  private

  def build_kind_approvals # rubocop:disable Metrics/CyclomaticComplexity
    previous_approved_by_others = true
    approval_kinds.map do |kind|
      approval = approvals.find { |a| a.approval_kind_id == kind.id }
      responsible = responsible_kinds.include?(kind)
      approvable = responsible && !approval&.approved? && previous_approved_by_others
      previous_approved_by_others = false if !responsible && !approval&.approved?
      Event::Tour::ApprovalKindApproval.new(
        approval_kind: kind,
        approval:,
        responsible:,
        approvable:
      )
    end
  end
end
