# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ApprovalKindApproval
  TRUE_VALUES = %w[true 1 yes]

  include ActiveModel::Model

  attr_reader :approval_kind, :responsible, :approvable, :checked
  attr_accessor :approval

  delegate :to_s, to: :approval_kind

  def initialize(approval_kind:, approval:, responsible:, approvable:)
    @approval_kind = approval_kind
    @approval = approval
    @responsible = responsible
    @approvable = approvable
    @checked = false
  end

  def checked=(value)
    @checked = TRUE_VALUES.include?(value.to_s)
  end

  def approval_kind_id
    approval_kind.id
  end

  def approved
    approval&.approved
  end

  def pre_check_approvable
    @checked = true if @approvable
  end
end
