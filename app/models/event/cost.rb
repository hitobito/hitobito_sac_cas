# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Cost < ApplicationRecord
  belongs_to :report, class_name: "Event::Report",
    inverse_of: :costs

  validates :description, :count, :amount, presence: true

  def total
    return 0 if amount.nil? || count.nil?

    amount * count
  end
end
