#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Pdf::Participations
  class LeaderSettlement
    class DecimalCountInvoiceItem < InvoiceItem
      attr_writer :count

      def count = (@count.to_i == @count) ? @count.to_i : @count
    end

    def initialize(participation, iban, options = {})
      @participation = participation
      @iban = iban
      @options = options
    end

    def render
      Export::Pdf::Invoice.render(invoice, options.merge(articles: true, payment_slip: true))
    end

    private

    attr_reader :participation, :iban, :options
    delegate :event, :person, to: :participation

    def invoice
      @invoice ||= build_invoice
    end

    def build_invoice # rubocop:disable Metrics/MethodLength
      invoice_items = build_invoice_items
      address_attrs = Contactable::Address.new(person).invoice_payee_address_attributes

      invoice_attrs = address_attrs
        .merge(SacAddressPresenter.new.format(:leader_settlement_invoice_attributes))
        .merge(
          iban:,
          currency: "CHF",
          payment_purpose: "Kurs #{event.number}",
          payment_slip: "qr",
          title: title,
          address: sender_address,
          sequence_number: sequence_number,
          issued_at: invoice_date,
          reference: nil,
          letter_address_position: :right,
          invoice_config: InvoiceConfig.new,
          creator: person,
          invoice_items:,
          total: invoice_items.sum(&:cost)
        )

      Invoice.new(invoice_attrs)
    end

    def sender_address = Person::Address.new(person).for_letter_with_invoice

    def title = "#{event.number} — #{event.name}"

    def invoice_date = @invoice_date ||= Time.zone.today

    def sequence_number = "#{person.id}-#{invoice_date.strftime("%Y-%m-%d")}"

    def build_invoice_items
      daily_compensation_items + other_compensation_items
    end

    def daily_compensation_items
      build_items(:day, participation.actual_days)
    end

    def other_compensation_items
      (compensations_by_kind.keys - [:day]).flat_map do |kind|
        build_items(kind, 1)
      end
    end

    def build_items(kind, count)
      role_type = participation.highest_leader_role_type
      compensations_by_kind.fetch(kind, []).map do |compensation|
        category = compensation.course_compensation_category
        name = category.send(:"name_#{role_type}").presence || category.short_name
        unit_cost = compensation.send(:"rate_#{role_type}")
        attrs = {name: name, count: count, unit_cost: unit_cost, cost: unit_cost * count}
        (kind == :day) ? DecimalCountInvoiceItem.new(attrs) : InvoiceItem.new(attrs)
      end
    end

    def compensations_by_kind
      @compensations_by_kind ||=
        event.compensation_rates
          .joins(:course_compensation_category)
          .where(course_compensation_categories: {leader_settlement: true})
          .includes(:course_compensation_category)
          .group_by { |rate| rate.course_compensation_category.kind.to_sym }
    end
  end
end
