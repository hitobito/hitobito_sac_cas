# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class SacRecipientRow < Export::Tabular::Row
    attr_reader :group

    def initialize(entry, group, format = nil)
      @group = group
      super(entry, format)
    end

    def adresszusatz
      # Adresszusatz wird allenfalls in INVOICE: Strukturierte Adressen bei Rechnungen / ISO20022
      # hitobito#2226 hinzugefügt, bis dahin eine leere Spalte in den Export schreiben
    end

    # Immer den Wert 0 ausgeben.
    def anzahl
      0
    end

    def country
      return if entry.country == "CH"

      Country.new(entry.country).name
    end

    # Navision ID des exportierten Layers als Zahl, ohne Zero-Padding
    def layer_navision_id
      group.layer_group.navision_id
    end

    def postfach
      # Postfach wird allenfalls in INVOICE: Strukturierte Adressen bei
      # Rechnungen / ISO20022 hitobito#2226 hinzugefügt, bis dahin eine leere Spalte
      # in den Export schreiben
    end

    # Inhalt: leer lassen, müsste ein Legacy-Feld sein das nicht mehr wirklich verwendet wird
    def salutation
      nil
    end
  end
end
