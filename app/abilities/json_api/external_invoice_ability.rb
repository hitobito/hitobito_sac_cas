# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class JsonApi::ExternalInvoiceAbility
  include CanCan::Ability

  def initialize(user)
    @user = user

    allow_index if backoffice?
  end

  private

  attr_reader :user

  def allow_index
    can :index, ExternalInvoice
  end

  def backoffice?
    user.roles.map(&:class).any? { |r| SacCas::SAC_BACKOFFICE_ROLES.include?(r) }
  end
end
