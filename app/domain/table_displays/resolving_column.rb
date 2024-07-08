# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module TableDisplays
  class ResolvingColumn < TableDisplays::Column
    def required_permission(attr)
      TableDisplays::Resolver::ATTRS.fetch(attr)
    end

    def required_model_attrs(_attr)
      []
    end

    def label(attr)
      TableDisplays::Resolver.new(template, nil, attr).label
    end

    def render(attr)
      return if TableDisplays::Resolver.exclude?(attr.to_sym, template.parent)

      super do |person|
        TableDisplays::Resolver.new(template, person, attr).to_s
      end
    end

    def sort_by(_attr)
      nil
    end
  end
end
