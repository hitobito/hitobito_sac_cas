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
      Export::Pdf::Invoice.render(invoice, options.merge(articles: true, payment_slip: true))
    end

    private

    attr_reader :participation, :iban, :options
    delegate :event, :person, to: :participation

    def invoice
      @invoice ||= Invoice.new(
        iban: iban,
        currency: "CHF",
        payment_purpose: "Kurs #{event.number}",
        payment_slip: "qr",
        title: title,
        payee: sender_address,
        address: sender_address,
        recipient_address: SacAddressPresenter.new.format(:leader_settlement),
        sequence_number: sequence_number,
        issued_at: invoice_date,
        reference: nil,
        letter_address_position: :right,
        invoice_config: InvoiceConfig.new,
        creator: person,
        invoice_items: build_invoice_items
      ).tap do |invoice|
        invoice.total = invoice.invoice_items.sum(&:cost)
      end
    end

    def sender_address = Person::Address.new(person).for_invoice

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
      compensations_by_kind.fetch(kind, []).map do |compensation|
        category = compensation.course_compensation_category
        name = category.send(:"name_#{role_type}").presence || category.short_name
        unit_cost = compensation.send(:"rate_#{role_type}")
        InvoiceItem.new(name: name, count: count, unit_cost: unit_cost, cost: unit_cost * count)
      end
    end

    def compensations_by_kind
      @compensations_by_kind ||=
        event.compensation_rates
          .includes(:course_compensation_category)
          .group_by { |rate| rate.course_compensation_category.kind.to_sym }
    end

    def role_type
      @role_type ||= find_highest_role_type.demodulize.underscore
    end

    def find_highest_role_type
      Event::Course::LEADER_ROLES.find do |type|
        participation.roles.any? { |role| role.type == type }
      end
    end
  end
end
