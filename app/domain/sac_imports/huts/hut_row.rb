# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class HutRow < Row
    class_attribute :type
    class_attribute :category
    class_attribute :owned_by_geschaeftsstelle

    GESCHAEFTSSTELLE_NAVISION_ID = "00001000"

    def can_process?
      row[:verteilercode] == 4000 && row[:hut_category] == category && right_owner?
    end

    def import!
      parent.children.find_or_create_by!(navision_id: related_navision_id) do |g|
        g.type = parent.class.const_get(type)
        g.name = @row[:related_last_name]
      end
    end

    private

    def right_owner?
      owned_by_geschaeftsstelle ? geschaeftsstelle? : !geschaeftsstelle?
    end

    def parent
      layer_id = Group.find_by(navision_id: contact_navision_id).id
      Group.const_get(type + "n").find_by(layer_group_id: layer_id)
    end

    def geschaeftsstelle? = row[:contact_navision_id] == GESCHAEFTSSTELLE_NAVISION_ID
  end
end
