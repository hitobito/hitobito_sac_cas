# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Event::Role
  extend ActiveSupport::Concern

  prepended do
    after_save :update_event_cached_leaders, if: :type_previously_changed?
    after_destroy :update_event_cached_leaders
  end

  private

  def update_event_cached_leaders
    return unless self.class.leader?

    event.update_cached_leaders
  end
end
