# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::CostReceipt < ApplicationRecord
  MAX_FILE_SIZE = Settings.event.attachments.max_file_size.megabytes
  CONTENT_TYPES = Settings.event.attachments.content_types

  belongs_to :report, class_name: "Event::Report",
    inverse_of: :cost_receipts

  has_one_attached :file

  validates :description, presence: true
  validates :file, attached: true,
    size: {less_than_or_equal_to: MAX_FILE_SIZE},
    content_type: CONTENT_TYPES
end
