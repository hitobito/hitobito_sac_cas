# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::Membership::VerifyController < ActionController::Base # rubocop:disable Rails/ApplicationController

  helper_method :person, :root, :member?, :membership_roles

  skip_authorization_check

  def show
    render layout: false
  end

  private

  def person
    @person ||= fetch_person
  end

  def fetch_person
    token = params[:verify_token]
    return nil if token.blank?

    Person.find_by(membership_verify_token: token)
  end

  def root
    Group.root.decorate
  end

  def member?
    @member ||= membership_verifier.member?
  end

  def membership_roles
    @membership_roles ||= membership_verifier.membership_roles
  end

  def membership_verifier
    @membership_verifier ||= People::MembershipVerifier.new(person)
  end

end
