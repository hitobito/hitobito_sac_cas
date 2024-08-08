# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MembershipInvoicesHelper
  def invoice_possible?
    context = Invoices::SacMemberships::Context.new(Time.zone.today)
    member = Invoices::SacMemberships::Member.new(@person, @context)
    memberships = member.active_memberships
    memberships.present? && Invoices::Abacus::MembershipInvoice.new(member, memberships).invoice?
  end

  def already_member_next_year?
    delete_on_date = @person.sac_membership.stammsektion_role.delete_on
    delete_on_date >= Date.new(Date.today.year + 1, 1, 1) && delete_on_date <= Date.new(Date.today.year + 1, 12, 31)
  end

  def currently_paying_zusatzsektionen
    member = Invoices::SacMemberships::Member.new(@person, @context)
    memberships = member.additional_membership_roles + member.new_additional_section_membership_roles
      .select { |membership| member
      .paying_person?(membership.beitragskategorie) }
    memberships.map(&:layer_group)
  end
end
