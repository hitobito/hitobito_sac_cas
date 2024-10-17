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
class ExternalInvoice::Course < ExternalInvoice
  # link is an Event::Participation object for a Event::Course

  NOT_POSSIBLE_KEY = "people.course_invoices.no_invoice_possible"

  after_save :update_participation_invoice_state

  class << self
    def invoice_participation(participation)
      return if participation.price.nil? || ExternalInvoice::Course.exists?(link: participation)

      external_invoice = ExternalInvoice::Course.create(
        person: participation.person,
        issued_at: Date.current,
        sent_at: Date.current,
        state: :draft,
        total: participation.price,
        link: participation,
        year: participation.event.dates.order(:start_at).first.start_at.year
      )

      Invoices::Abacus::CreateCourseInvoiceJob.new(external_invoice).enqueue!
    end
  end

  def title
    "#{link.event.name} (#{link.event.number})"
  end

  private

  def update_participation_invoice_state
    if newest_participation_invoice?
      link.update!(invoice_state: state)
    end
  end

  def newest_participation_invoice?
    self.class.where(link: self.link).order(created_at: :desc).first == self
  end
end
