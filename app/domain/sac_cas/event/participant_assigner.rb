#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::ParticipantAssigner
  extend ActiveSupport::Concern

  def set_active(active)
    participation.update!(active: active, state: active ? "assigned" : "unconfirmed")
  end
end
