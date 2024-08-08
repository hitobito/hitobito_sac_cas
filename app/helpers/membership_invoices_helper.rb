# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MembershipInvoicesHelper
  def invoice_possible?(member, date)
    memberships = member.active_memberships
    memberships.present? && Invoices::Abacus::MembershipInvoice.new(member, memberships).invoice?
  end

  def already_member_next_year?(person)
    next_year = Time.zone.today.year + 1
    delete_on_date = person.sac_membership.stammsektion_role.delete_on
    delete_on_date >= Date.new(next_year, 1, 1) && delete_on_date <= Date.new(next_year, 12, 31)
  end

  def currently_paying_zusatzsektionen(member)
    memberships = member.additional_membership_roles + member.new_additional_section_membership_roles
    paying_memberships = memberships.select { |membership| member.paying_person?(membership.beitragskategorie) }
    paying_memberships.map(&:layer_group)
  end
end
