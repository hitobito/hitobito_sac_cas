#  Copyright (c) 2025, Schweizer Alpen Club This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Sheet::Group
  extend ActiveSupport::Concern

  prepended do
    tabs.insert(4,
      Sheet::Tab.new("activerecord.models.event/tour.other",
        :tour_group_events_path,
        params: {returning: true},
        if: lambda do |view, group|
          group.event_types.include?(::Event::Tour) &&
            group.tours_enabled &&
            view.can?(:"index_event/tours", group)
        end))
  end

  def show?
    return false if current_person&.basic_permissions_only? && controller.is_a?(Event::ParticipationsController)

    super
  end
end
