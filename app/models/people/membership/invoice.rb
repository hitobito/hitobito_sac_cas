# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Membership::Invoice
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :reference_date, :invoice_date, :send_date, :discount, :new_entry, :section_id

  validates :reference_date, :invoice_date, :send_date, presence: true

  validate :reference_date_within_range
  validate :invoice_date_within_range
  validate :send_date_within_range

  validates :discount, inclusion: {in: ["0", "50", "100"]}

  def initialize(attributes = {}, person = nil)
    super(attributes)
    @person = person
  end

  private

  def reference_date_within_range
    date_within_range(reference_date, :reference_date)
  end

  def invoice_date_within_range
    date_within_range(invoice_date, :invoice_date)
  end

  def date_within_range(date, field)
    if date.present? && !(date_today.beginning_of_year..date_today.next_year.end_of_year).cover?(Date.parse(date))
      errors.add(field, :invalid_date_range, start_on: date_today.beginning_of_year, end_on: date_today.next_year.end_of_year)
    end
  end

  def send_date_within_range
    if @person && send_date.present?
      delete_on = @person.sac_membership.stammsektion_role.delete_on

      valid_range = if delete_on.year > date_today.year
        date_today.all_year
      else
        date_today.beginning_of_year..date_today.next_year.end_of_year
      end

      unless valid_range.cover?(Date.parse(send_date))
        errors.add(:send_date, :invalid_date_range, start_on: valid_range.begin, end_on: valid_range.end)
      end
    end
  end

  def date_today
    Time.zone.today
  end
end
