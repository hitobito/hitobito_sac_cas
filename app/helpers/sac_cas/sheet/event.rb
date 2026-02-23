#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

module SacCas::Sheet::Event
  extend ActiveSupport::Concern

  class_methods do
    def parent_sheet_for(view_context)
      @parent_sheet_for ||= if view_context.current_person&.basic_permissions_only? &&
          view_context.controller.is_a?(::Event::ParticipationsController)
        nil
      else
        Sheet::Group
      end
    end
  end

  def path_args
    return super if parent_sheet.present?
    [entry.groups.first, entry]
  end
end
