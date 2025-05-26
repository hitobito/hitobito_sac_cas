# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # Event::Course
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav18 = Data.define(
    :name_de, # Name_DE
    :name_fr, # Name_FR
    :name_it, # Name_IT
    :kind, # Kursart
    :number, # Kursnummer
    :state, # Status
    :description_de, # Beschreibung_DE
    :description_fr, # Beschreibung_FR
    :description_it, # Beschreibung_IT
    :contact_id, # Kontaktperson
    :location, # Ort_Adresse
    :cost_center, # Kostenstelle
    :cost_unit, # Kostenträger
    :minimum_age, # Mindestalter
    :maximum_age, # Maximalalter
    :minimum_participants, # Minimale_TN_Zahl
    :maximum_participants, # Maximale_TN_Zahl
    :ideal_class_size, # Ideale_Klassengrösse
    :maximum_class_size, # Maximale_Klassengrösse
    :training_days, # Ausbildungstage
    :season, # Saison
    :accommodation, # Unterkunft
    :reserve_accommodation, # Unterkunft_reservieren_durch_SAC_reservieren_durch_SAC
    :meals, # Verpflegung
    :globally_visible, # Sichtbarkeit
    :language, # Sprache
    :annual, # Jährlich_wiederkehrend
    :start_point_of_time, # Kursbeginn
    :application_opening_at, # Anmeldebeginn
    :application_closing_at, # Anmeldeschluss
    :application_conditions_de, # Aufnahmebedingungen_DE
    :application_conditions_fr, # Aufnahmebedingungen_FR
    :application_conditions_it, # Aufnahmebedingungen_IT
    :external_applications, # Externe_Anmeldungen
    :participations_visible, # Teilnehmersichtbarkeit
    :priorization, # Priorisierung
    :automatic_assignment, # Automatische_Zuteilung
    :signature, # Unterschift_erforderlich
    :signature_confirmation, # Zweitunterschrift_erforderlich
    :signature_confirmation_text, # Zweitunterschrift
    :applications_cancelable, # Abmeldung_möglich
    :display_booking_info, # Anzeige_Anmeldestand
    :price_member, # Mitgliederpreis
    :price_regular, # Normalpreis
    :price_subsidized, # Subventionierter_Preis
    :price_js_active_member, # J_S_A_Mitgliederpreis
    :price_js_active_regular, # J_S_A_Normalpreis
    :price_js_passive_member, # J_S_P_Mitgliederpreis
    :price_js_passive_regular, # J_S_P_Normalpreis
    :brief_description_de, # Kurzbeschreibung_DE
    :brief_description_fr, # Kurzbeschreibung_FR
    :brief_description_it, # Kurzbeschreibung_IT
    :specialities_de, # Besonderes_DE
    :specialities_fr, # Besonderes_FR
    :specialities_it, # Besonderes_IT
    :similar_tours_de, # Vergleichstouren_DE
    :similar_tours_fr, # Vergleichstouren_FR
    :similar_tours_it, # Vergleichstouren_IT
    :program_de, # Programm_DE
    :program_fr, # Programm_FR
    :program_it, # Programm_IT
    :link_participants, # Link_Teilnehmer
    :link_leaders, # Link_Kurskader
    :link_survey, # Link_Umfrage
    :book_discount_code, # Rabattcode_Buchversand
    :canceled_reason, # Annulationsgrund
    :nav19_number, # NAV19_Kurs (selbes wie Kursnummer)
    :date_label, # NAV19_Bezeichnung
    :date_location, # NAV19_Ort
    :date_start_at, # NAV19_Von
    :date_finish_at # NAV19_Bis
  )
end
