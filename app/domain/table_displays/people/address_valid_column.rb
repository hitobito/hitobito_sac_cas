# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class AddressValidColumn < TableDisplays::Column
    def required_model_attrs(attr)
      []
    end

    def required_model_includes(attr)
      [:tags]
    end

    def render(attr)
      super do |person|
        address_valid(person)
      end
    end

    def required_permission(attr)
      :show
    end

    private

    def allowed_value_for(target, target_attr, &block)
      address_valid(target)
    end

    def address_valid(person)
      invalid_tags = person.tags.select { |tag| tag.name == PersonTags::Validation::ADDRESS_INVALID }
      invalid_tags.empty? ? I18n.t(:"global.yes") : I18n.t(:"global.no")
    end
  end
end
