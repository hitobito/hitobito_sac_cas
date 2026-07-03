#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Export::AlpsRecipientsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :reference_date, :date, default: -> { Date.current }
  attribute :new_entries_from, :date

  validates :reference_date, presence: true
  validates_date :new_entries_from, on_or_before: :reference_date, allow_blank: true
end
