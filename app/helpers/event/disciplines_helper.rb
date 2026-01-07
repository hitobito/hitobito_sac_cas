# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Event::DisciplinesHelper
  def disciplines_select_options(main_disciplines)
    main_disciplines.flat_map do |main|
      main.children.sort_by(&:order).map do |child|
        {id: child.id, label: child.to_s, description: child.short_description, group: main.id}
      end
    end.to_json
  end

  def disciplines_select_optgroups(main_disciplines)
    main_disciplines.flat_map do |main|
      {value: main.id, label: main.to_s}
    end.to_json
  end
end
