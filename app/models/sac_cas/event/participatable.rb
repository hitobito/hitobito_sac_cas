# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::Participatable
  extend ActiveSupport::Concern

  def refresh_participant_counts!
    super
    update_column(:unconfirmed_count, distinct_count(unconfirmed_scope))
  end

  private

  def unconfirmed_scope
    participations.where(state: :unconfirmed)
  end
end
