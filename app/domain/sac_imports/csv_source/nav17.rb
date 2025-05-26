# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # Event::Kinds
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav17 = Data.define(
    :label_de, # Bezeichnung_DE
    :label_fr, # Bezeichnung_FR
    :label_it, # Bezeichnung_IT
    :short_name, # Kurzname
    :kind_category, # Kurskategorie
    :general_information_de, # Standardbeschreibung_DE
    :general_information_fr, # Standardbeschreibung_FR
    :general_information_it, # Standardbeschreibung_IT
    :application_conditions_de, # Aufnahmebedingungen_DE
    :application_conditions_fr, # Aufnahmebedingungen_FR
    :application_conditions_it, # Aufnahmebedingungen_IT
    :level, # Kursstufe
    :cost_center, # Kostenstelle
    :cost_unit, # Kostenträger
    :course_compensation_categories, # Vergütungskategorien
    :minimum_age, # Mindestalter
    :maximum_age, # Maximalalter
    :minimum_participants, # Minimale_TN_Zahl
    :maximum_participants, # Maximale_TN_Zahl
    :ideal_class_size, # Ideale_Klassengrösse
    :maximum_class_size, # Maximale_Klassengrösse
    :training_days, # Ausbildungstage
    :season, # Saison
    :accommodation, # Unterkunft
    :reserve_accommodation, # Unterkunft_reservieren_durch_SAC
    :section_may_create, # Von_Sektion_erstellbar
    :precondition, # Vorbedingungen
    :qualification, # Qualifiziert_für
    :prolongation # Verlängert
  )
end
