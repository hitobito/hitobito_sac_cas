# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::TokenAbility
  def layer_group_descendants_ids
    token_layer_and_below.flat_map { |g| g.self_and_descendants.map(&:id) }
  end

  private

  def define_token_abilities
    super

    define_external_invoice_abilities if token.external_invoices
  end

  def define_external_invoice_abilities
    can :index_external_invoices, Group, {layer_group_id: layer_group_ids}
    can :index, ExternalInvoice, {link_type: Group.sti_name, link_id: layer_group_descendants_ids}
    can :update, ExternalInvoiceAbility do |g|
    end
    can [:read, :update], ExternalInvoice, {link_type: Group.sti_name, link_id: layer_group_descendants_ids}
  end

  def layer_group_ids
    # This would avoid loading all the groups
    # token_layer_and_below.flat_map { |g| [g.lft, g.rgt] }.minmax
    token_layer_and_below.map(&:id)
  end
end
