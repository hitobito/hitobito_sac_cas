# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfRegistrationController
  extend ActiveSupport::Concern

  def create
    return redirect_to_login if email_taken?

    super
  end

  def entry
    return super unless [
      Group::SektionsNeuanmeldungenNv::Neuanmeldung,
      Group::SektionsNeuanmeldungenSektion::Neuanmeldung
    ].include?(group.class)

    @entry ||= SelfRegistration.new(
      group: group,
      params: params.to_unsafe_h.deep_symbolize_keys
    )
  end

  def model_class
    @model_class ||= Groups::SacRegistrationWizards.for(group)
  end

  private

  def email_taken?
    main_person_email = entry.person.email.presence or return false

    Person.where(email: main_person_email).exists?
  end

  def redirect_to_login
    store_location_for(entry.person, group_self_inscription_path(group))

    path = new_person_session_path(person: { login_identity: entry.person.email })
    notice = t('.redirect_existing_email')

    return redirect_to(path, notice: notice) unless request.xhr?

    flash[:notice] = notice
    render js: "window.location='#{path}';"
  end
end
