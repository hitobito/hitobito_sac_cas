# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfRegistrationController
  extend ActiveSupport::Concern

  delegate :email, to: :wizard

  prepended do
    before_action :restrict_access
  end

  private

  def restrict_access
    return redirect_to_login if !signed_in? && email_exists?
    return redirect_to_memberships_tab if member_or_applied?
    redirect_to_person_show if family?
  end

  def email_exists? = email.present? && Person.exists?(email: email)

  def family? = current_user&.household&.present?

  def member_or_applied?
    current_user&.sac_membership&.stammsektion_role ||
      current_user&.sac_membership&.neuanmeldung_stammsektion_role
  end

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

  def redirect_to_login
    person = Person.find_by(email: email)
    store_location_for(person, group_self_registration_path(group))

    path = new_person_session_path(person: {login_identity: email})
    notice = t("groups.self_registration.create.redirect_existing_email")

    return redirect_to(path, notice: notice) unless request.xhr?

    flash[:notice] = notice
    render js: "window.location='#{path}';"
  end

  def redirect_to_memberships_tab
    flash[:notice] = t("groups.self_registration.create.existing_membership_notice")
    redirect_to history_group_person_path(group_id: current_user.primary_group_id, id: current_user.id)
  end

  def redirect_to_person_show
    flash[:notice] = t("groups.self_registration.create.existing_family_notice")
    redirect_to history_group_person_path(group_id: current_user.primary_group_id, id: current_user.id)
  end

  def redirect_to_group_if_necessary
    redirect_to group_path(group) unless group.self_registration_active?
  end

  def redirect_target
    if current_user.present?
      history_group_person_path(group_id: current_user.reload.primary_group_id, id: current_user.id)
    else
      new_person_session_path
    end
  end

  def success_message
    if current_user.present?
      t("groups.self_registration.create.signed_up_notice")
    else
      super
    end
  end
end
