# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas
  ### Membership roles

  MITGLIED_STAMMSEKTION_ROLES = [::Group::SektionsMitglieder::Mitglied].freeze
  NEUANMELDUNG_STAMMSEKTION_ROLES = [
    ::Group::SektionsNeuanmeldungenNv::Neuanmeldung,
    ::Group::SektionsNeuanmeldungenSektion::Neuanmeldung
  ]

  MITGLIED_ZUSATZSEKTION_ROLES = [::Group::SektionsMitglieder::MitgliedZusatzsektion].freeze
  NEUANMELDUNG_ZUSATZSEKTION_ROLES = [
    ::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
    ::Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion
  ]

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
  ]

  SAC_SECTION_FUNCTIONARY_ROLES = [
    ::Group::SektionsFunktionaere::Administration,
    ::Group::SektionsFunktionaere::Praesidium,
    ::Group::SektionsFunktionaere::Mitgliederverwaltung
  ]

  TOUR_GUIDE_ROLES = [
    ::Group::SektionsTourenUndKurse::Tourenleiter,
    ::Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation
  ]

  ###

  NEWSLETTER_MAILING_LIST_INTERNAL_KEY = "sac_newsletter"

  def main_phone_label
    Settings.phone_number.predefined_labels.find { |l| l =~ /Haupt/ }
  end

  module_function :main_phone_label
end
