# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::ApprovalCommissionResponsibilityComponents
  extend ActiveSupport::Concern

  included do
    has_many :event_approval_commission_responsibilities,
      dependent: nil,
      class_name: "Event::ApprovalCommissionResponsibility"

    after_real_destroy :destroy_approval_commission_responsibilities
  end

  private

  def destroy_approval_commission_responsibilities
    event_approval_commission_responsibilities.destroy_all
  end
end
