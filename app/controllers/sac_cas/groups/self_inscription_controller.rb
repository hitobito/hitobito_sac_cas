# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfInscriptionController
  extend ActiveSupport::Concern

  def new
    # validate calls #set_beitragskategorie on the role which calculates the beitragskategorie
    # from the person's age
    @role = build_role.tap(&:validate)

    # Neuanmeldung Role is always in a Neuanmeldungen Group which has a generic title unusable
    # for the user to identify the group. Therefore we use the parent group's name instead.
    title_group = @role.class.name.ends_with?('::Neuanmeldung') ? @group.parent : @group
    @title = helpers.render_self_registration_title(title_group)
  end
end
