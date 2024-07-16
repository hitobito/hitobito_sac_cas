# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Dropdown::TableDisplays
  def render_item(_name, column, attr, _label = render_label(column, attr))
    super unless TableDisplays::Resolver.new(template, table_display.person, attr).exclude_attr?
  end
end
