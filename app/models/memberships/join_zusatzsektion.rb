# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class JoinZusatzsektion < JoinBase
    delegate :group_for_neuanmeldung, to: :join_section

    attr_reader :person, :join_section, :beitragskategorie

    def initialize(join_section, person, sac_family_membership: false, **params)
      super(join_section, person, **params)
      @sac_family_membership = sac_family_membership
      @beitragskategorie = derive_beitragskategorie

      raise "missing neuanmeldungen subgroup" unless group_for_neuanmeldung
    end

    def affected_people
      sac_family_membership? ? super : [person]
    end

    def save!
      generate_invoice(roles.first) unless confirmation_needed?

      super
    end

    private

    def confirmation_needed?
      group_for_neuanmeldung.is_a?(Group::SektionsNeuanmeldungenSektion)
    end

    def generate_invoice(role)
      invoice = ExternalInvoice::SacMembership.create!(
        person: role.person,
        state: :draft,
        year: Date.current.year,
        issued_at: Date.current,
        sent_at: Date.current,
        link: role.layer_group
      )
      Invoices::Abacus::CreateMembershipInvoiceJob.new(invoice, Date.current, new_entry: false).enqueue!
    end

    def prepare_roles(person)
      group_for_neuanmeldung.roles.build(
        person: person,
        type: group_for_neuanmeldung.class.const_get(:NeuanmeldungZusatzsektion),
        beitragskategorie: derive_beitragskategorie,
        start_on: now.to_date
      )
    end

    def derive_beitragskategorie
      if sac_family_membership?
        SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY
      else
        SacCas::Beitragskategorie::Calculator.new(person).calculate(for_sac_family: false)
      end
    end

    def validate_family_main_person?
      sac_family_membership?
    end

    def sac_family_membership?
      @sac_family_membership
    end
  end
end
