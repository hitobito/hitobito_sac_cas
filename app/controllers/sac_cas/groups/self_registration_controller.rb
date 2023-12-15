# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfRegistrationController
  extend ActiveSupport::Concern

  def create
    return super unless entry.redirect_to_login?

    redirect_to_login
  end

  private

  def entry
    @entry ||= SelfRegistration.for(group).new(
      group: group,
      params: params.to_unsafe_h.deep_symbolize_keys
    )
  end

  def redirect_to_login
    store_location_for(entry.main_person.person, group_self_inscription_path(group))

    redirect_to(
      new_person_session_path(person: { login_identity: entry.email }),
      notice: t('.redirect_existing_email')
    )
  end
end
