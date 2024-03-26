# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::MailingListsController

  # Discard params for which the current_user has no update permission.
  # The form should not have these fields in the first place, but to be sure
  # we simply ignore them here.
  def permitted_params
    super.then { |p| p.select { |attr| can?(:update, entry, attr) } }
  end

end
