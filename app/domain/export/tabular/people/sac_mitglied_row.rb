# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class SacMitgliedRow < Export::Tabular::Row
    BEITRAGSKATEGORIEN = {
      adult: "EINZEL",
      youth: "JUGEND",
      family: "FAMILIE"
    }.stringify_keys.freeze

    attr_reader :group

    def initialize(entry, group, format = nil)
      @group = group
      super(entry, format)
    end

    def adresszusatz
      entry.address_care_of
    end

    # Immer den Wert 0 ausgeben.
    # Der Versand von Die Alpen wird seit längerem nicht mehr über diesen
    # Adress-Export abgehandelt, sondern via Empfängerliste, was in
    # ABOS: Empfängerliste exportieren #427 implementiert wird.
    def anzahl_die_alpen
      0
    end

    # Immer den Wert 0 ausgeben.
    # Der Versand von Sektionsbulletins sollte seit längerem nicht mehr über diesen
    # Adress-Export abgehandelt werden, sondern via Empfängerliste, was in
    # ABOS: Empfängerliste exportieren #427 implementiert wird.
    def anzahl_sektionsbulletin
      0
    end

    # Begünstigt anhand Präsenz einer aktiven Rolle vom Typ Beguenstigt im exportierten Layer.
    # Mögliche Werte: Yes / No
    def begünstigt
      role_in_layer?(Group::SektionsMitglieder::Beguenstigt) ? "Yes" : "No"
    end

    # Beitragskategorie der Person in der exportierten Sektion / Ortsgruppe
    # Mögliche Werte: EINZEL / FAMILIE / KIND etc.
    # vorerst einfach die Kategorien die wir auf der Rolle verwenden
    def beitragskategorie
      return @beitragskategorie if defined?(@beitragskategorie)

      role = role_in_layer(*(SacCas::MITGLIED_ROLES - SacCas::NEUANMELDUNG_ROLES))
      @beitragskategorie = BEITRAGSKATEGORIEN[role&.beitragskategorie.to_s]
    end

    # Bemerkungen (Zusätzliche Daten, Person#additional_information)
    def bemerkungen
      entry.additional_information
    end

    # Geburtsdatum im Format dd.mm.yyyy
    def birthday
      entry.birthday&.strftime("%d.%m.%Y")
    end

    # Land als zwei-Buchstaben-Kürzel, z.B. DE, FR etc.; wenn Schweiz dann leer
    def country
      entry.country unless entry.country == "CH"
    end

    # Ehrenmitglied anhand Präsenz einer aktiven Rolle vom Typ Ehrenmitglied im exportierten Layer.
    # Mögliche Werte: Yes / No
    def ehrenmitglied
      role_in_layer?(Group::SektionsMitglieder::Ehrenmitglied) ? "Yes" : "No"
    end

    # Eintrittsjahr der allerersten Mitgliederrolle dieser Person,
    # egal welche Sektion gerade exportiert wird
    def eintrittsjahr
      entry.roles_unscoped.select do |role|
        SacCas::MITGLIED_ROLES.include?(role.class)
      end.map(&:start_on).min&.year
    end

    # Mögliche Werte: Weiblich / Männlich / Andere
    def gender
      case entry.gender
      when "w" then "Weiblich"
      when "m" then "Männlich"
      else "Andere"
      end
    end

    # Sprache Korrespondenzsprache der Person.
    # Mögliche Werte: D / F / ITS
    # (Englisch als Korrespondenzsprache wird für den SAC noch in separatem Ticket deaktiviert)
    def language
      case entry.language
      when "de" then "D"
      when "fr" then "F"
      when "it" then "ITS"
      else entry.language.upcase
      end
    end

    # Navision ID des exportierten Layers als Zahl, mit Zero-Padding
    def layer_id_padded
      group.id_padded
    end

    def phone_number_landline = entry.phone_number_landline&.number

    def phone_number_mobile = entry.phone_number_mobile&.number

    def postfach
      entry.postbox
    end

    def s_info_1
      entry.sac_remark_section_1
    end

    def s_info_2
      entry.sac_remark_section_2
    end

    def s_info_3
      entry.sac_remark_section_3
    end

    def saldo
      "0"
    end

    # Used for empty cells.
    def empty
      nil
    end

    private

    def role_in_layer(*role_classes)
      entry.roles.find do |role|
        role.group.layer_group_id == group.id && role_classes.include?(role.class)
      end
    end

    def role_in_layer?(...)
      role_in_layer(...).present?
    end
  end
end
