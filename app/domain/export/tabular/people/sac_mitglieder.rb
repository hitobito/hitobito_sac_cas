# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class SacMitglieder < Export::Tabular::SacGroupPeopleBase
    def initialize(group)
      unless group.is_a?(Group::Sektion) || group.is_a?(Group::Ortsgruppe)
        raise ArgumentError, "Argument must be a Sektion or Ortsgruppe"
      end

      @group = group
      super(mitglieder, group)
    end

    def labels
      nil
    end

    def attributes # rubocop:disable Metrics/MethodLength
      [
        :id,
        :layer_navision_id_padded,
        :last_name,
        :first_name,
        :adresszusatz,
        :address,
        :postfach,
        :zip_code,
        :town,
        :country,
        :birthday,
        :phone_number_main,
        :phone_number_privat,
        :empty, # 1 leere Spalte
        :phone_number_mobil,
        :phone_number_fax,
        :email,
        :gender,
        :empty, # 1 leere Spalte
        :language,
        :eintrittsjahr,
        :begünstigt,
        :ehrenmitglied,
        :beitragskategorie,
        :s_info_1,
        :s_info_2,
        :s_info_3,
        :bemerkungen,
        :saldo,
        :empty, # 1 leere Spalte
        :anzahl_die_alpen,
        :anzahl_sektionsbulletin
      ]
    end

    public :list

    private

    def mitglieder
      Person
        .where(roles: {
          group_id: non_layer_children_ids,
          type: SacCas::MITGLIED_ROLES.map(&:sti_name)
        })
        .joins(:roles)
        .includes(:phone_numbers, :roles, roles: :group)
        .distinct
    end

    def non_layer_children_ids
      group.children.reject(&:layer?).map(&:id)
    end
  end
end
