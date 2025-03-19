# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Event::Participation::InvoiceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :reference_date, :date
  attribute :invoice_date, :date
  attribute :send_date, :date
  attribute :price_category, :string
  attribute :price, :decimal

  validates :reference_date, :invoice_date, :send_date, :price, presence: true

  validates :price_category, presence: true, unless: :annulation
  validate :price_category_must_be_valid_participation_category, unless: :annulation

  attr_reader :participation, :annulation

  def initialize(participation, attrs = {}, annulation: false)
    super(attrs)
    @participation = participation
    @annulation = annulation
  end

  def price_category_must_be_valid_participation_category
    valid_categories = participation.class.price_categories.values + participation.class.price_categories.keys

    unless valid_categories.include?(price_category)
      errors.add(:price_category, "is not a valid category for the participation")
    end
  end
end
