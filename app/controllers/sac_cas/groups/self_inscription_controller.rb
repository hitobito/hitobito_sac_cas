# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfInscriptionController
  extend ActiveSupport::Concern

  # always redirect to self registration, self inscription is currently not used in the sac wagon
  # self registration is also possible for logged in users, so there is no need for self inscription
  def show
    redirect_to group_self_registration_path
  end
end
