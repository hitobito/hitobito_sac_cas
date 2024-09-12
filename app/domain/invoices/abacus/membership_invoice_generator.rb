# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Invoices::Abacus::MembershipInvoiceGenerator
  def initialize(person_id, section, reference_date, custom_discount: nil)
    @person_id = person_id
    @reference_date = reference_date
    @section = section
    @custom_discount = custom_discount
  end

  def build(new_entry: false)
    Invoices::Abacus::MembershipInvoice.new(
      member,
      memberships,
      new_entry:
    )
  end

  private

  attr_reader :section, :person_id, :reference_date, :custom_discount

  def memberships
    if stammsektion?
      active_memberships
    elsif neuanmeldung_stammsektion?
      neuanmeldung_stammsektion_memberships
    elsif zusatzsektion?
      zusatzsektion_memberships
    else
      []
    end
  end

  def active_memberships
    member.active_memberships
  end

  def neuanmeldung_stammsektion_memberships
    [member.membership_from_role(member.neuanmeldung_nv_stammsektion_roles.first, main: true)]
  end

  def zusatzsektion_memberships
    zusatzsektion_roles
      .select { |role| role.layer_group == section }
      .map { |r| member.membership_from_role(r) }
  end

  def stammsektion? = section_matches?([member.stammsektion_role])

  def neuanmeldung_stammsektion? = section_matches?(member.neuanmeldung_nv_stammsektion_roles)

  def zusatzsektion? = section_matches?(zusatzsektion_roles)

  def zusatzsektion_roles = member.zusatzsektion_roles + member.neuanmeldung_nv_zusatzsektion_roles

  def section_matches?(roles) = roles.compact.map(&:layer_group).include?(section)

  def member = @member ||= Invoices::SacMemberships::Member.new(person, context)

  def context = @context ||= Invoices::SacMemberships::Context.new(reference_date, custom_discount: custom_discount)

  def person = context.people_with_membership_years(includes: []).find(person_id).tap do |p|
    ActiveRecord::Associations::Preloader.new.preload([p], :roles, Role.with_deleted)
  end
end
