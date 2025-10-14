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

  validates :section_id, :reference_date, :invoice_date, :send_date, :discount, presence: true

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

  private

  attr_reader :person

  def assert_active_membership
    unless active_membership_section_ids.include?(section_id)
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
