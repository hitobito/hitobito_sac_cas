#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventParticipationsHelper
  def event_participation_table_options(t, event:, group:)
    t.sortable_attr(:state)
    if parent.possible_participation_states.any?
      t.sortable_attr(:state)
    end
    if event.course? && can?(:create, event)
      t.col(t(".key_data_sheets")) do |p|
        if p.roles.map(&:class).any?(&:leader?)
          link_to(icon(:file_pdf), group_event_key_data_sheets_path(group, event, {participation_ids: p.id}), method: :post)
        end
      end
    end
  end
end
