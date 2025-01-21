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
        invalid_tags = person.tags.select { |tag| tag.name == PersonTags::Validation::ADDRESS_INVALID }
        template.f(invalid_tags.empty?)
      end
    end

    def required_permission(attr)
      :show
    end
  end
end
