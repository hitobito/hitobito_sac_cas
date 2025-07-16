# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Devise::Hitobito::SessionsController
  extend ActiveSupport::Concern

  prepended do
    prepend_before_action :redirect_if_unconfirmed, only: :create # rubocop:disable Rails/LexicallyScopedActionFilter
  end

  private

  def redirect_if_unconfirmed
    person = find_person_by_login_identity

    if person&.valid_password?(params.dig(:person, :password))
      person.send_confirmation_instructions
      redirect_to new_session_path(:person), alert: t("devise.sessions.create.confirm_email_before_logging_in")
    end
  end

  def find_person_by_login_identity
    login_identity = params.dig(:person, :login_identity)
    Person.devise_login_id_attrs.reduce(Person.none) do |scope, attr|
      scope.or(Person.where(attr => login_identity))
    end.first
  end
end
