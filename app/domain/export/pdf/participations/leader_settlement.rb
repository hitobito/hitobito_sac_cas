#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Pdf::Participations
  class LeaderSettlement
    MARGIN = 2.5.cm

    def initialize(participation, iban, options = {})
      @participation = participation
      @iban = iban
      @options = options
    end

    def render
      pdf = Export::Pdf::Document.new.pdf
      invoice = Invoice.new(iban: @iban, 
                            payee: Person::Address.new(@participation.person).for_invoice, 
                            currency: "CHF", 
                            payment_purpose: "Kurs #{@participation.event.number}", 
                            recipient_address: "Schweizer Alpen-Club SAC\nZentralverband, Monbijoustrasse 61\n3000 Bern 14\n\n\n", 
                            total: 100, title: "Testrechnung", 
                            esr_number: "12345", 
                            sequence_number: "1-1", 
                            reference: "12345", 
                            group_id: 1)
      Export::Pdf::Invoice::PaymentSlipQr.new(pdf, invoice, @options).render
      pdf.render
    end
  end
end