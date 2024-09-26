# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Neuanmeldungen::Promoter
  CONDITIONS = [
    NoDuplicateCondition,
    VerifiedEmailCondition,
    PaidInvoiceCondition
  ].freeze

  NEUANMELDUNG_ROLES = SacCas::NEUANMELDUNG_ROLES.map(&:sti_name).freeze
  OBSOLETE_ROLES = [
    Group::AboTourenPortal::Abonnent,
    Group::AboTourenPortal::Neuanmeldung,
    Group::AboMagazin::Abonnent,
    Group::AboMagazin::Neuanmeldung,
    Group::AboBasicLogin::BasicLogin
  ].map(&:sti_name).freeze

  ERROR_CATEGORY = "neuanmeldungen"

  def call
    candidate_roles.find_each { |role| promote(role) }
  end

  def promote(role)
    promote_role(role) if promotable?(role)
  end

  def promotable?(role)
    conditions_satisfied?(role)
  end

  def candidate_roles
    # We do not handle FutureRoles here. They will be included once they are converted to regular
    # Neuanmeldung roles.
    Role.where(type: [
      Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
      Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name
    ]).includes(:person)
  end

  private

  def promote_role(role)
    Role.transaction do
      role.destroy!
      terminate_and_destroy_obsolete_roles!(role)
      create_member_role!(role)
    end
  rescue => e
    log_error(e, role)
  end

  def create_member_role!(role)
    target_role_class(role).create!(
      group: target_group(role),
      person: role.person,
      beitragskategorie: role.beitragskategorie,
      created_at: Time.current,
      delete_on: Date.current.end_of_year
    )
  end

  def terminate_and_destroy_obsolete_roles!(role)
    now = Time.zone.today

    role.person.roles
      .where(type: OBSOLETE_ROLES, created_at: now...)
      .or(role.person.roles.where(type: NEUANMELDUNG_ROLES, created_at: ..now))
      .find_each { |role| role.really_destroy! }

    role.person.roles.where(created_at: ..now).find_each do |role|
      Roles::Termination.new(
        role:,
        terminate_on: role.created_at.today? ? now : now.yesterday,
        validate_terminate_on: false
      ).call
    end
  end

  def target_role_class(role)
    if role.class.sti_name.ends_with?("NeuanmeldungZusatzsektion")
      Group::SektionsMitglieder::MitgliedZusatzsektion
    else
      Group::SektionsMitglieder::Mitglied
    end
  end

  def target_group(role)
    role.group.layer_group.children.find { |child| child.is_a?(Group::SektionsMitglieder) }
  end

  def conditions_satisfied?(role)
    CONDITIONS.all? { |condition| condition.satisfied?(role) }
  end

  def log_error(error, role)
    Hitobito.logger.error_replace(
      ERROR_CATEGORY,
      error.message.presence || error.class.name,
      subject: role.person,
      payload: {
        person: {id: role.person.id, name: role.person.full_name},
        role: {id: role.id, type: role.class.name},
        group: {id: role.group.id, path: role.group.hierarchy.map(&:name).join("/")}
      }
    )
  end
end
