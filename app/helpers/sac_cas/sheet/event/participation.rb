# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Sheet::Event::Participation
  extend ActiveSupport::Concern

  prepended do
    tabs.insert(1, Sheet::Tab.new(
      "event.participations.tabs.history",
      :history_group_event_participation_path,
      if: :show_details
    ))

    class << self
      def parent_sheet_for(view_context)
        if signup?(view_context)
          nil
        else
          Sheet::Event
        end
      end

      def signup?(view_context)
        view_context.controller.is_a?(Event::ParticipationsController) &&
          %w[new create].include?(view_context.action_name)
      end
    end
  end
end
