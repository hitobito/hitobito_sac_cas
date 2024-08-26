# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::YearlyMembership::InvoiceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :invoice_year, :integer
  attribute :invoice_date, :date
  attribute :send_date, :date
  attribute :role_finish_date, :date

  validates :invoice_year, :invoice_date, :send_date, presence: true

  validates :invoice_year, inclusion: {in: ->(f) { [f.min_year, f.max_year] }}, allow_blank: true

  validates_date :invoice_date, between: [:min_date, :max_date], allow_blank: true
  validates_date :send_date, between: [:min_date, :max_date], allow_blank: true
  validates_date :role_finish_date, between: [:min_date, :max_date], allow_blank: true

  def min_year = min_date.year

  def max_year = max_date.year

  def min_date = today.beginning_of_year

  def max_date = today.next_year.end_of_year

  private

  attr_reader :person

  def today = Time.zone.today
end
