# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People::Neuanmeldungen
  # Approve Neuanmeldungen
  #
  # In the given group for all People with the given people_ids their Role
  # `Group::SektionsNeuanmeldungenSektion::Neuanmeldung` will be replaced
  # with a Role `Group::SektionsNeuanmeldungenNv::Neuanmeldung`.
  #
  # Example:
  #   People::Neuanmeldungen::Approve.new(group: group, people_ids: people_ids).call
  #
  class Approve < Base
    def call
      applicable_roles.each do |role|
        Role.transaction do
          role.destroy!
          next unless create_approved_role?(role)

          create_approved_role(role)
          generate_invoice(role) if paying_person?(role)
          send_confirmation_mail(role.person) if paying_person?(role)
        end
      end
    end

    private

    def approved_roles_group
      @approved_roles_group ||=
        group
          .parent.children.without_deleted
          .find_by(type: APPROVED_NEUANMELDUNGEN_GROUP.sti_name) ||
        APPROVED_NEUANMELDUNGEN_GROUP.create!(parent: group.parent)
    end

    def create_approved_role?(role)
      approved_roles_group.roles
        .where(type: APPROVED_NEUANMELDUNGEN_ROLE.sti_name, person_id: role.person_id)
        .none?
    end

    def create_approved_role(role)
      APPROVED_NEUANMELDUNGEN_ROLE.create!(
        group: approved_roles_group,
        person: role.person,
        beitragskategorie: role.beitragskategorie,
        created_at: role.created_at,
        delete_on: role.delete_on
      )
    end

    def generate_invoice(role)
      invoice = ExternalInvoice::SacMembership.create!(
        person: role.person,
        state: :draft,
        year: Date.current.year,
        issued_at: Date.current,
        sent_at: Date.current,
        link: role.layer_group
      )
      Invoices::Abacus::CreateMembershipInvoiceJob.new(invoice, Date.current, new_entry: true).enqueue!
    end

    def send_confirmation_mail(person)
      People::NeuanmeldungenMailer.approve(person, group.layer_group).deliver_later
    end
  end
end
