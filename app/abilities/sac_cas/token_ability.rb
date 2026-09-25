# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::TokenAbility
  extend ActiveSupport::Concern

  prepended do
    ApiScopeAbility::REQUIRED_SCOPES[:"Event::Level"] = :events
    ApiScopeAbility::REQUIRED_SCOPES[:"Event::Activity"] = :events
    ApiScopeAbility::REQUIRED_SCOPES[:"Event::FitnessRequirement"] = :events
    ApiScopeAbility::REQUIRED_SCOPES[:"Event::TargetGroup"] = :events
    ApiScopeAbility::REQUIRED_SCOPES[:"Event::TechnicalRequirement"] = :events
    ApiScopeAbility::REQUIRED_SCOPES[:"Event::Trait"] = :events
  end

  private

  def initialize(token)
    super

    can :manage, ExternalInvoice if token.layer.root?

    if token.events?
      can :"index_event/tours", Group do |g|
        token_layer_and_below.include?(g)
      end
    end
  end
end
