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

    def address
      [entry.street, entry.housenumber].join(" ").strip
    end

    # Immer den Wert 1 ausgeben
    def anzahl
      1
    end

    def country
      return if entry.country == "CH"

      Country.new(entry.country).name
    end

    # Navision ID des exportierten Layers als Zahl, ohne Zero-Padding
    def layer_id
      group.layer_group.id
    end

    def salutation
      return if entry.gender.nil?

      I18n.with_locale(entry.language) do
        I18n.t(entry.gender, scope: "activerecord.attributes.person.recipient_salutations")
      end
    end
  end
end
