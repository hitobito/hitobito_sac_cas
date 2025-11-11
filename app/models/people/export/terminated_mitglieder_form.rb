#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Export::TerminatedMitgliederForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :group

  attribute :from, :date, default: -> { Date.current.beginning_of_year }
  attribute :to, :date, default: -> { Date.current.end_of_year }

  validates :from, :to, presence: true
  validates_date :to,
    allow_blank: true,
    on_or_after: :from,
    on_or_after_message: :must_be_later_than_from,
    if: -> { from.present? }

  validate :assert_max_date_range_length

  def assert_max_date_range_length
    unless to.between?(from - 1.year, from + 1.year)
      errors.add(:base, :date_range_too_long)
    end
  end
end
