#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Pdf::Participations
  class LeaderSettlement
    attr_reader :participation, :iban, :options

    def initialize(participation, iban, options = {})
      @participation = participation
      @iban = iban
      @options = options
    end

    def render
      pdf = create_pdf_document
      invoice = prepare_invoice
      render_payment_slip(pdf, invoice)
      pdf.render
    end

    private

    def create_pdf_document = Export::Pdf::Document.new.pdf

    def formatted_payee_address = Person::Address.new(participation.person).for_invoice

    def payment_purpose_text = "Kurs #{participation.event.number}"

    def recipient_address_text = "Schweizer Alpen-Club SAC\nZentralverband, Monbijoustrasse 61\n3000 Bern 14\n\n\n"

    def render_payment_slip(pdf, invoice) = Export::Pdf::Invoice::PaymentSlipQr.new(pdf, invoice, options).render

    def total_amount = (day_compensation_total * participation&.actual_days) + non_day_compensation_total

    def day_compensation_total = compensation_amount("day")

    def non_day_compensation_total = compensation_amount("non_day")

    def prepare_invoice
      Invoice.new(
        iban: iban,
        payee: formatted_payee_address,
        currency: "CHF",
        payment_purpose: payment_purpose_text,
        recipient_address: recipient_address_text,
        total: total_amount,
        sequence_number: "1-1",
        reference: nil
      )
    end

    def compensation_amount(kind)
      compensations(kind).map do |compensation|
        compensation.send(:"rate_#{relevant_event_role.type.demodulize.underscore}")
      end.sum || 0
    end

    def compensations(kind)
      participation.event.compensation_rates.select do |rate|
        kind == "day" ? rate.course_compensation_category.kind == "day" : rate.course_compensation_category.kind != "day"
      end
    end

    def relevant_event_role
      participation.roles.find { |r| r.type == Event::Role::Leader.sti_name } ||
        participation.roles.find { |r| r.type == Event::Role::AssistantLeader.sti_name }
    end
  end
end
