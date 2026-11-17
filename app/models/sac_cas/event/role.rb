# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::Role
  extend ActiveSupport::Concern

  prepended do
    after_save :update_event_cached_leaders, if: :type_previously_changed?
    after_destroy :update_event_cached_leaders
  end

  private

  def update_event_cached_leaders
    return unless self.class.leader?

    # event (has_one through) joins event_participations, which is
    # already deleted after destroying the participation's last role
    # so we use the in-memory participation
    participation.event.update_cached_leaders
  end
end
