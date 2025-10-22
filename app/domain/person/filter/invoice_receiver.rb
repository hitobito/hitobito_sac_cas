# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Person::Filter::InvoiceReceiver < Person::Filter::Base
  VISIBLE_ATTRS = [:stammsektion, :zusatzsektion, :deep].freeze
  self.permitted_args = [*VISIBLE_ATTRS, :group_id]

  def initialize(...)
    super
    @args[:deep] = true if root?
  end

  def apply(scope)
    return scope if blank?

    invoice_receiver_scope(scope.select(:id))
  end

  def blank? = !(stammsektion || zusatzsektion) || group_id.blank?

  private

  def stammsektion = ActiveModel::Type::Boolean.new.cast(args[:stammsektion])

  def zusatzsektion = ActiveModel::Type::Boolean.new.cast(args[:zusatzsektion])

  def deep = ActiveModel::Type::Boolean.new.cast(args[:deep])

  def group_id = args[:group_id].presence

  def role_types
    [].tap do |role_types|
      role_types << Group::SektionsMitglieder::Mitglied.sti_name if stammsektion
      role_types << Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name if zusatzsektion
    end
  end

  def base_scope(scope)
    scope
      .joins(roles: :group)
      .where(roles: {type: role_types})
      .then { |scope| filter_by_layers(scope) }
  end

  def filter_by_layers(scope)
    return scope if root?
    return scope.where(groups: {layer_group_id: group_id}) unless deep

    layers = Group.find(group_id).self_and_descendants.where("groups.id = groups.layer_group_id")
    scope.where(groups: {layer_group_id: layers.select(:id)})
  end

  def invoice_receiver_scope(scope)
    base_scope(scope)
      .where.not(roles: {beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY})
      .or(base_scope(scope).where(sac_family_main_person: true))
  end

  def root? = group_id.to_i == Group.root_id
end
