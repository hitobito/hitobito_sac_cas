# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Membership::InvoiceForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  DISCOUNTS = [0, 50, 100].freeze

  attribute :reference_date, :date
  attribute :invoice_date, :date
  attribute :send_date, :date
  attribute :dont_send, :boolean
  attribute :discount, :integer
  attribute :new_entry, :boolean
  attribute :section_id, :integer

  attribute :sac_fee, :integer, default: 0
  attribute :sac_entry_fee, :integer
  attribute :hut_solidarity_fee, :integer, default: 0
  attribute :sac_magazine, :integer, default: 0
  attribute :sac_magazine_postage_abroad, :integer, default: 0
  attribute :section_entry_fee, :integer

  # Arrays of People::Membership::InvoiceSectionFeeForm
  attribute :section_fees, array: true
  attribute :section_bulletin_postage_abroad, array: true

  validates :section_id, :reference_date, :invoice_date, :send_date, presence: true
  validates :discount, presence: true, unless: :manual_positions?

  validates_date :reference_date, :invoice_date, between: [:min_date, :max_date], allow_blank: true
  validates_date :send_date, between: [:min_date, :max_send_date], allow_blank: true

  validates :discount, inclusion: {in: DISCOUNTS}, allow_blank: true
  validate :assert_active_membership, if: :assert_active_membership?

  delegate :sac_membership, to: :person
  delegate :stammsektion_role, :neuanmeldung_stammsektion_role, :select_paying, to: :sac_membership
  delegate :zusatzsektion_roles, :neuanmeldung_nv_zusatzsektion_roles, to: :ref_date_sac_membership

  def initialize(person, attrs = {})
    super(attrs)
    @person = person
  end

  def stammsektion
    select_paying([stammsektion_role, neuanmeldung_stammsektion_role]).first&.layer_group
  end

  def zusatzsektionen
    select_paying(neuanmeldung_nv_zusatzsektion_roles + zusatzsektion_roles).map(&:layer_group)
  end

  def min_date = @min_date ||= today.beginning_of_year

  def max_date = @max_date ||= today.next_year.end_of_year

  def max_send_date = already_member_next_year? ? today.next_year.end_of_year : today.end_of_year

  def manual_positions
    return {} unless manual_positions?

    [
      :sac_fee,
      :sac_entry_fee,
      :hut_solidarity_fee,
      :sac_magazine,
      :sac_magazine_postage_abroad,
      :section_entry_fee
    ].index_with { send(_1) }.tap do |positions|
      positions[:section_fees] = section_fees_hash
      positions[:section_bulletin_postage_abroads] = section_bulletin_postage_abroad_hash
    end
  end

  def section_fees_attributes=(attributes)
    self.section_fees = attributes.values.map do |attrs|
      People::Membership::InvoiceSectionFeeForm.new(Group.find(attrs[:section_id]), attrs)
    end
  end

  def section_bulletin_postage_abroad_attributes=(attributes)
    self.section_bulletin_postage_abroad_attributes = attributes.values.map do |attrs|
      People::Membership::InvoiceSectionFeeForm.new(Group.find(attrs[:section_id]), attrs)
    end
  end

  def manual_positions? = section_id.zero?

  def section_bulletin_postage_abroad_hash = section_bulletin_postage_abroad&.map(&:attributes)

  def section_fees_hash = section_fees&.map(&:attributes)

  def sac_fee_type = :number

  def sac_entry_fee_type = :number

  def hut_solidarity_fee_type = :number

  def sac_magazine_type = :number

  def sac_magazine_postage_abroad_type = :number

  def section_entry_fee_type = :number

  private

  attr_reader :person

  def assert_active_membership
    unless manual_positions? || active_membership_section_ids.include?(section_id)
      errors.add(:section_id, :invalid)
    end
  end

  def assert_active_membership?
    section_id.present? && (min_date..max_date).cover?(reference_date)
  end

  def already_member_next_year?
    sac_membership.active? && (stammsektion_role.end_on&.year&.>= today.next_year.year)
  end

  def today = @today ||= Time.zone.today

  def ref_date_sac_membership = @ref_date_sac_membership ||= People::SacMembership.new(person,
    date: reference_date)

  def active_membership_section_ids = ([ref_date_stammsektion] + zusatzsektionen).compact.map(&:id)

  def ref_date_stammsektion
    select_paying([ref_date_sac_membership.stammsektion_role,
      ref_date_sac_membership.neuanmeldung_stammsektion_role]).first&.layer_group
  end
end
