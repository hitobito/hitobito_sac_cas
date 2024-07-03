# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Sheet::Person
  extend ActiveSupport::Concern

  prepended do
    self.tabs.insert(1, Sheet::Tab.new(
      'people.tabs.remarks',
      :group_person_sac_remarks_path,
      if: ->(view, _group, person) { view.can?(:show_remarks, person) }
    ))
  end
end
