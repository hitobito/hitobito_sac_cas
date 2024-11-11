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
      Export::Pdf::Invoice::PaymentSlipQr.new(pdf, invoice, @options).render
      pdf.render
    end

    def invoice
      @invoice = Invoice.new(iban: @iban, payee: "TODO", recipient_address: "TODO", total: 100, title: "TODO", esr_number: "TODO", sequence_number: "TODO", reference: "TODO", group_id: 1)
    end

    def pdf = @pdf = Export::Pdf::Document.new(margin: MARGIN).pdf
  end
end