# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# This module referencing a lot of constants leads to those classes being loaded before
# they normally would be loaded by being referenced in the wagon.rb for example.
# This has specifically already lead to an issue where the Group::FreigabeKomitee class has been
# loaded earlier than the Group superclass has had the module SacPhoneNumbers prepended on it.
# Thus the associations defined by SacPhoneNumbers were missing on Group::FreigabeKomitee.
module SacCas
  ### Membership roles

  MITGLIED_STAMMSEKTION_ROLES = [::Group::SektionsMitglieder::Mitglied].freeze
  NEUANMELDUNG_NV_STAMMSEKTION_ROLES = [::Group::SektionsNeuanmeldungenNv::Neuanmeldung].freeze
  NEUANMELDUNG_STAMMSEKTION_ROLES = [
    ::Group::SektionsNeuanmeldungenNv::Neuanmeldung,
    ::Group::SektionsNeuanmeldungenSektion::Neuanmeldung
  ].freeze

  MITGLIED_ZUSATZSEKTION_ROLES = [::Group::SektionsMitglieder::MitgliedZusatzsektion].freeze
  # rubocop:todo Layout/LineLength
  NEUANMELDUNG_NV_ZUSATZSEKTION_ROLES = [::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion].freeze
  # rubocop:enable Layout/LineLength
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

  SAC_BACKOFFICE_ROLES = [
    ::Group::Geschaeftsstelle::Mitarbeiter,
    ::Group::Geschaeftsstelle::Admin
  ].freeze

  SAC_SECTION_FUNCTIONARY_ROLES = [
    ::Group::SektionsFunktionaere::Administration,
    ::Group::SektionsFunktionaere::Praesidium,
    ::Group::SektionsFunktionaere::Mitgliederverwaltung
  ].freeze

  SAC_SECTION_MEMBER_ADMIN_ROLE_TYPES = [
    ::Group::SektionsMitglieder::Schreibrecht,
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

  BACKOFFICE_DESTROYABLE_ROLES = [
    NEUANMELDUNG_ROLES,
    ::Group::AboMagazin::Neuanmeldung,
    ::Group::AboTourenPortal::Neuanmeldung
  ].flatten.freeze

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
    .reject { |c| c.to_s =~ /MAILING_LIST_SEKTIONSBULLETIN.*INTERNAL_KEY/ }
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

  MEMBERSHIP_OPERATIONS_GROUP_TYPES = %w[Group::Sektion Group::Ortsgruppe].freeze
  MEMBERSHIP_OPERATIONS_EXCLUDED_IDS = [
    3700, # CAS Monte Rosa
    2249, # CAS Diablerets
    2330, # SAC Drei Tannen (archiviert)
    2601, # SAC Gotthard Frauen (archiviert)
    3030, # CAS Jorat (Frauen-Biel) (archiviert)
    3251, # SAC Laegern Zurzach (archiviert)
    3730, # CAS Mont-Soleil (archiviert)
    3952, # SAC O'aargau H'buchsWang. (archiviert)
    3953, # Oberaargau Herzogenbuchs (archiviert)
    3954, # SAC Oberaargau Langenthal (archiviert)
    4530, # CAS Raimeux (archiviert)
    4851, # SAC Seeland Erlach (archiviert)
    5401  # CAS Val-De-Joux dames (archiviert)
  ]
end
