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

  validates_date :reference_date, :invoice_date, between: Time.zone.today.beginning_of_year..Time.zone.today.next_year.end_of_year
  validates_date :send_date, between: [Time.zone.today.beginning_of_year, :send_date_end_date]

  validates :discount, inclusion: {in: DISCOUNTS}

  def initialize(attributes = {}, person = nil)
    super(attributes)
    @person = person
  end

  private

  def send_date_end_date
    @person.sac_membership.stammsektion_role.delete_on.year > date_today.year ? date_today.end_of_year : date_today.next_year.end_of_year
  end

  def date_today
    Time.zone.today
  end
end
