# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Export::Tabular::People
  class AlpsRecipients < Export::Tabular::Base
    self.model_class = ::Person
    self.row_class = AlpsRecipientRow
    self.styled_attrs = {
      date: [:birthday, :entry_date]
    }

    class_attribute :attribute_labels
    self.attribute_labels = {
      id: "nr",
      name: "name",
      first_name: "vorname",
      address_care_of: "adresszusatz",
      address: "adresse",
      postbox: "postfach",
      country: "laendercode",
      zip_code: "plz",
      town: "ort",
      amount: "anzahl_alpen",
      language: "sprache",
      birthday: "geburtsdatum",
      entry_on: "eintrittsdatum",
      type: "typ",
      company: "firma"
    }

    attr_reader :reference_date, :full, :abonnent_group_langs

    def initialize(scope, reference_date, abonnent_group_langs, full: false)
      super(scope)
      @reference_date = reference_date
      @abonnent_group_langs = abonnent_group_langs
      @full = full
    end

    def attribute_labels
      if full
        self.class.attribute_labels
      else
        self.class.attribute_labels.except(:birthday, :entry_on, :type, :company)
      end
    end

    private

    def row_for(entry, format = nil)
      row_class.new(entry, reference_date, abonnent_group_langs)
    end
  end
end
