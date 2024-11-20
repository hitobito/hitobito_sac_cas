#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Pdf::Participations
  class LeaderSettlement
    def initialize(participation, iban, options = {})
      @participation = participation
      @iban = iban
      @options = options
    end

    def render
      Export::Pdf::Document.new.pdf.tap do |pdf|
        Export::Pdf::Invoice::PaymentSlipQr.new(pdf, invoice, options).render
      end.then(&:render)
    end

    private

    attr_reader :participation, :iban, :options

    def invoice
      @invoice ||= Invoice.new(
        iban: iban,
        payee: Person::Address.new(participation.person).for_invoice,
        currency: "CHF",
        payment_purpose: "Kurs #{participation.event.number}",
        recipient_address: SacAddressPresenter.new.format(:leader_settlement),
        total: daily_compensations + other_compensations,
        sequence_number: "1-1",
        reference: nil
      )
    end

    def daily_compensations = participation.actual_days * compensation_amount(:day)

    def other_compensations = (compensations_by_kind.keys - [:day]).sum { |key| compensation_amount(key) }

    def compensation_amount(kind)
      compensations_by_kind.fetch(kind, []).map do |compensation|
        compensation.send(:"rate_#{relevant_event_role.type.demodulize.underscore}")
      end.sum || 0
    end

    def compensations_by_kind
      @compensations_by_kind ||= participation.event.compensation_rates
        .group_by { |rate| rate.course_compensation_category.kind.to_sym }
    end

    def relevant_event_role
      participation.roles.find { |r| Event::Course::LEADER_ROLES.include?(r.type) }
    end
  end
end
