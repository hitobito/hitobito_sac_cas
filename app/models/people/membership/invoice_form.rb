# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Membership::InvoiceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  DISCOUNTS = ["0", "50", "100"].freeze

  attribute :reference_date, :date
  attribute :invoice_date, :date
  attribute :send_date, :date
  attribute :discount, :string
  attribute :new_entry, :boolean
  attribute :section_id, :string

  validates :reference_date, :invoice_date, :send_date, :discount, presence: true

  validates_date :reference_date, :invoice_date, between: [:min_date, :max_date], allow_blank: true
  validates_date :send_date, between: [:min_date, :max_send_date], allow_blank: true

  validates :discount, inclusion: {in: DISCOUNTS}

  def initialize(attributes = {}, person = nil)
    super(attributes)
    @person = person
  end

  def date_range(attr = nil)
    max_date = (attr == :send_date && !already_member_next_year?) ? date_today.end_of_year : date_today.next_year.end_of_year

    {minDate: date_today.beginning_of_year, maxDate: max_date}
  end

  private

  def already_member_next_year?
    next_year = date_today.next_year.year
    @person.sac_membership.stammsektion_role.delete_on&.year&.>= next_year
  end

  def min_date = date_range[:minDate]

  def max_date = date_range[:maxDate]

  def max_send_date = date_range(:send_date)[:maxDate]

  def date_today = Time.zone.today
end
