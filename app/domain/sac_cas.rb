# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas
  ### Membership roles

  MITGLIED_STAMMSEKTION_ROLES = [::Group::SektionsMitglieder::Mitglied].freeze
  NEUANMELDUNG_NV_STAMMSEKTION_ROLES = [::Group::SektionsNeuanmeldungenNv::Neuanmeldung].freeze
  NEUANMELDUNG_STAMMSEKTION_ROLES = [
    ::Group::SektionsNeuanmeldungenNv::Neuanmeldung,
    ::Group::SektionsNeuanmeldungenSektion::Neuanmeldung
  ].freeze

  MITGLIED_ZUSATZSEKTION_ROLES = [::Group::SektionsMitglieder::MitgliedZusatzsektion].freeze
  NEUANMELDUNG_NV_ZUSATZSEKTION_ROLES = [::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion].freeze
  NEUANMELDUNG_ZUSATZSEKTION_ROLES = [
    ::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
    ::Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion
  ].freeze

  MITGLIED_ROLES = [
    MITGLIED_STAMMSEKTION_ROLES,
    MITGLIED_ZUSATZSEKTION_ROLES
  ].flatten.freeze

  NEUANMELDUNG_ROLES = [
    NEUANMELDUNG_STAMMSEKTION_ROLES,
    NEUANMELDUNG_ZUSATZSEKTION_ROLES
  ].flatten.freeze

  MITGLIED_AND_NEUANMELDUNG_ROLES = [
    MITGLIED_ROLES,
    NEUANMELDUNG_ROLES
  ].flatten.freeze

  STAMMSEKTION_ROLES = [
    MITGLIED_STAMMSEKTION_ROLES,
    NEUANMELDUNG_STAMMSEKTION_ROLES
  ].flatten.freeze

  ZUSATZSEKTION_ROLES = [
    MITGLIED_ZUSATZSEKTION_ROLES,
    NEUANMELDUNG_ZUSATZSEKTION_ROLES
  ].flatten.freeze

  ### Various roles

  EVENT_LEADER_ROLES = [::Event::Course::Role::Leader, ::Event::Course::Role::AssistantLeader].freeze

  SAC_BACKOFFICE_ROLES = [
    ::Group::Geschaeftsstelle::Mitarbeiter,
    ::Group::Geschaeftsstelle::Admin
  ].freeze

  SAC_SECTION_FUNCTIONARY_ROLES = [
    ::Group::SektionsFunktionaere::Administration,
    ::Group::SektionsFunktionaere::Praesidium,
    ::Group::SektionsFunktionaere::Mitgliederverwaltung
  ].freeze

  TOUR_GUIDE_ROLES = [
    ::Group::SektionsTourenUndKurse::Tourenleiter,
    ::Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation
  ].freeze

  ABONNENT_MAGAZIN_ROLES = [
    ::Group::AboMagazin::Abonnent,
    ::Group::AboMagazin::Neuanmeldung
  ].freeze

  ABONNENT_TOUREN_PORTAL_ROLES = [
    ::Group::AboTourenPortal::Abonnent
  ].freeze

  # Prevent those from being edited via roles UI
  WIZARD_MANAGED_ROLES = [
    ::Group::SektionsMitglieder::Mitglied,
    ::Group::SektionsMitglieder::MitgliedZusatzsektion,
    ::Group::SektionsNeuanmeldungenNv::Neuanmeldung,
    ::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
    ::Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
    ::Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion,
    ::Group::AboMagazin::Abonnent,
    ::Group::AboMagazin::Neuanmeldung,
    ::Group::AboTourenPortal::Abonnent,
    ::Group::AboTourenPortal::Neuanmeldung
  ].freeze

  MEMBERSHIP_PROLONGABLE_ROLES = [
    ::Group::Ehrenmitglieder::Ehrenmitglied,
    ::Group::SektionsMitglieder::Ehrenmitglied,
    ::Group::SektionsMitglieder::Beguenstigt
  ]

  ###

  MV_EMAIL = "mv@sac-cas.ch"
  MAILING_LIST_SAC_NEWSLETTER_INTERNAL_KEY = "sac_newsletter"
  MAILING_LIST_SAC_INSIDE_INTERNAL_KEY = "sac_inside"
  MAILING_LIST_TOURENLEITER_INTERNAL_KEY = "tourenleiter"
  MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY = "die_alpen_paper"
  MAILING_LIST_DIE_ALPEN_DIGITAL_INTERNAL_KEY = "die_alpen_digital"
  MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY = "spendenaufrufe"
  MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY = "sektionsbulletin_paper"
  MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY = "sektionsbulletin_digital"

  PROTECTED_MAILING_LISTS_INTERNAL_KEYS = constants(false)
    .select { |c| c.to_s =~ /MAILING_LIST_.*INTERNAL_KEY/ }
    .map { |c| const_get(c) }

  AboCost = Data.define(:amount, :country)
  ABO_COSTS = {
    magazin: [
      AboCost.new(amount: 60, country: :switzerland),
      AboCost.new(amount: 76, country: :international)
    ],
    tourenportal: [
      AboCost.new(amount: 45, country: nil)
    ]
  }

  MEMBERSHIP_OPERATIONS_GROUP_TYPES = [::Group::Sektion.sti_name, ::Group::Ortsgruppe.sti_name].freeze
  MEMBERSHIP_OPERATIONS_EXCLUDED_IDS = [
    2900, 3700, 2249, 2330, 2601, 3030, 3251,
    3730, 3952, 3953, 3954, 4530, 4851, 5401
  ]

  def main_phone_label
    Settings.phone_number.predefined_labels.find { |l| l =~ /Haupt/ }
  end

  module_function :main_phone_label
end
