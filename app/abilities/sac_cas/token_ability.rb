# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::TokenAbility
  private

  def define_invoice_abilities
    super

    can :manage, ExternalInvoice if token.layer.root?
    can :manage, Event::Level if token.layer.root?
  end

  def define_event_abilities
    super

    can :"index_event/tours", Group do |g|
      token_layer_and_below.include?(g)
    end
  end
end
