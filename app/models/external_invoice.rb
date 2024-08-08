# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: external_invoices
#
#  id                     :bigint           not null, primary key
#  abacus_sales_order_key :integer
#  issued_at              :date
#  link_type              :string(255)
#  sent_at                :date
#  state                  :string(255)      default("draft"), not null
#  total                  :decimal(12, 2)   default(0.0), not null
#  type                   :string(255)      not null
#  year                   :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  link_id                :bigint
#  person_id              :bigint           not null
#
# Indexes
#
#  index_external_invoices_on_link       (link_type,link_id)
#  index_external_invoices_on_person_id  (person_id)
#
class ExternalInvoice < ActiveRecord::Base
  STATES = %w[draft open payed cancelled error]

  include I18nEnums

  belongs_to :person
  belongs_to :link, polymorphic: true, optional: true
  has_many :hitobito_log_entries, as: :subject, dependent: :nullify

  i18n_enum :state, STATES, scopes: true, queries: true

  validates_by_schema
  validates :state, inclusion: {in: STATES}

  scope :list, -> { order(:created_at) }

  def type_key
    self.class.name.demodulize.underscore
  end

  def cancellable?
    abacus_sales_order_key.present? && state != "cancelled" && state != "error"
  end

  def title = id

  def to_s = "#{title} #{person}"
end
