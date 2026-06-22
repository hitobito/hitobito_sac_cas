# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Report < ApplicationRecord
  model_stamper
  stampable stamper_class_name: :person, deleter: false

  belongs_to :event
  belongs_to :submitter, class_name: "Person", optional: true
  belongs_to :approver, class_name: "Person", optional: true
  belongs_to :payer, class_name: "Person", optional: true

  has_many :costs, dependent: :destroy,
    class_name: "Event::Cost",
    inverse_of: :report

  has_many :cost_receipts, dependent: :destroy,
    class_name: "Event::CostReceipt",
    inverse_of: :report

  def status
    return :closed if paid_at?
    return :approved if approved_at?
    return :review if submitted_at?
    :draft
  end
end
