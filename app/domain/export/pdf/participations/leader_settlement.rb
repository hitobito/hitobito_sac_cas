#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Pdf::Participations
  class LeaderSettlement
    attr_reader :participation, :iban, :options, :pdf, :invoice

    def initialize(participation, iban, options = {})
      @participation = participation
      @iban = iban
      @options = options
      @pdf = Export::Pdf::Document.new.pdf
      @invoice = build_invoice
    end

    def render
      render_payment_slip
      pdf.render
    end

    private

    def formatted_payee_address = Person::Address.new(participation.person).for_invoice

    def payment_purpose_text = "Kurs #{participation.event.number}"

    def render_payment_slip = Export::Pdf::Invoice::PaymentSlipQr.new(pdf, invoice, options).render

    def total_amount = (compensation_amount("day") * participation&.actual_days) + compensation_amount("non_day")

    def build_invoice
      Invoice.new(
        iban: iban,
        payee: formatted_payee_address,
        currency: "CHF",
        payment_purpose: payment_purpose_text,
        recipient_address: SacAddressPresenter.new.format(:leader_settlement),
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
        (kind == "day") ? rate.course_compensation_category.kind == "day" : rate.course_compensation_category.kind != "day"
      end
    end

    def relevant_event_role
      participation.roles.find { |r| r.type == Event::Course::Role::Leader.sti_name } ||
        participation.roles.find { |r| r.type == Event::Course::Role::AssistantLeader.sti_name }
    end
  end
end
