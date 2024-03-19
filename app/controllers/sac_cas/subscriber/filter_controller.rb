# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Subscriber::FilterController

  # We use the core implementation but add an authorization check.
  def edit
    authorize_update!
    super
  end

  # We use the core implementation but add an authorization check.
  def update
    authorize_update!
    super
  end

  private

  # Only allow updating if the current user has the permission to update the filter chain.
  def authorize_update!
    current_ability.authorize!(:update, mailing_list, :filter_chain)
  end

end
