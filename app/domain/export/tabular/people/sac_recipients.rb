# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class SacRecipients < Export::Tabular::SacGroupPeopleBase

    def attributes
      [
        :id,
        :salutation,
        :first_name,
        :last_name,
        :adresszusatz,
        :address,
        :postfach,
        :zip_code,
        :town,
        :country,
        :layer_navision_id,
        :anzahl,
        :email
      ]
    end

    def address_label
      'Strasse'
    end

    def id_label
      'Navision-Nr.'
    end

    def last_name_label
      'Name'
    end

    def layer_navision_id_label
      'Sektion'
    end

    def email_label
      'E-Mail'
    end

  end
end
