# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Wizards::RegisterNewUsersController
  extend ActiveSupport::Concern

  delegate :email, to: :wizard

  def create
    return super unless person

    redirect_to_login
  end

  private

  def model_class
    case group
    when Group::AboBasicLogin
      Wizards::Signup::AboBasicLoginWizard
    when Group::AboTourenPortal
      Wizards::Signup::AboTourenPortalWizard
    when Group::AboMagazin
      Wizards::Signup::AboMagazinWizard
    when Group::SektionsNeuanmeldungenNv, Group::SektionsNeuanmeldungenSektion
      Wizards::Signup::SektionWizard
    else
      super
    end
  end

  def person
    @person ||= Person.find_by(email: email)
  end

  def redirect_to_login
    store_location_for(person, group_self_inscription_path(group))

    path = new_person_session_path(person: {login_identity: email})
    notice = t("groups.self_registration.create.redirect_existing_email")

    return redirect_to(path, notice: notice) unless request.xhr?

    flash[:notice] = notice
    render js: "window.location='#{path}';"
  end
end
