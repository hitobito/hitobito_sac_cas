#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Event::Courses::LeaderSettlementForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :course

  attribute :iban, :string
  attribute :actual_days, :decimal

  validates :iban, presence: true, iban: true

  validates :actual_days, presence: true
  validates :actual_days, numericality: {greater_than_or_equal_to: 0}, if: -> {
    actual_days.present?
  }
  validate :actual_days_cannot_exceed_course_days, if: -> { actual_days.present? }

  def actual_days_cannot_exceed_course_days
    if actual_days > course.total_event_days
      errors.add(:actual_days, I18n.t("errors.messages.total_event_days_exceeded"))
    end
  end
end
