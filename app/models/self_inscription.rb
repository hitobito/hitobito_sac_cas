# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SelfInscription
  include ActiveModel::Model
  include ActiveModel::Attributes
  include FutureRole::FormHandling

  attr_accessor :person, :group
  attribute :register_on, :string, default: 'now'
  attribute :register_as, :string, default: 'replace'

  delegate :beitragskategorie_label, to: :role

  validates_presence_of :person, :group, :register_on, :register_as
  validates :register_on, inclusion: { in: :register_on_keys, allow_blank: true }
  validates :register_as, inclusion: { in: :register_as_keys, allow_blank: true }

  def initialize(person:, group:, **opts)
    super
  end

  def group_for_title
    role.class.name.ends_with?('::Neuanmeldung') ? @group.parent : @group
  end

  def neuanmeldung?
    @group.is_a?(Group::SektionsNeuanmeldungenSektion) ||
    @group.is_a?(Group::SektionsNeuanmeldungenNv)
  end

  def register_as_options
    build_options(:register_as, register_as_keys)
  end

  def active_member?
    sektion_membership_roles.exists?
  end

  def active_in_sektion?
    sektion_membership_roles.joins(:group).where(groups: { parent_id: @group.parent_id }).exists?
  end

  def save!
    Role.transaction do
      register_on_date ? save_future_role : save_role
    end
  end

  private

  def register_as_keys
    active_member? ? %w(extra replace) : %w(replace)
  end

  def save_role
    if replace_active_membership?
      active_membership_role.destroy!(always_soft_destroy: true)
      active_membership_role.update_column(:deleted_at, 1.day.ago.end_of_day)
    end
    role.save!
  end

  def save_future_role
    if replace_active_membership?
      active_membership_role.update!(delete_on: register_on_date - 1.day)
    end

    FutureRole.create!(
      person: role.person,
      group: role.group,
      convert_to: role.type,
      convert_on: register_on_date
    )
  end

  def replace_active_membership?
    active_member? && register_as.match(/replace/)
  end

  def active_membership_role
    @active_membership_role ||= sektion_membership_roles.find_by(group_id: @person.primary_group_id)
  end

  def sektion_membership_roles
    person.roles.where(type: Group::SektionsMitglieder::Mitglied.sti_name)
  end

  def role
    @role ||= role_type.new(
      group: @group,
      person: @person,
      # TODO: in a later ticket: what values should we set for the timestamps?
      # https://github.com/hitobito/hitobito_sac_cas/issues/178
      created_at: Time.current,
      delete_on: (today.end_of_year unless neuanmeldung?)
    ).tap(&:valid?)
  end

  def role_type
    return @group.self_registration_role_type.constantize unless neuanmeldung?

    case register_as
      when /replace/ then @group.class.const_get('Neuanmeldung')
      when /extra/ then @group.class.const_get('NeuanmeldungZusatzsektion')
      else Role # won't be valid anyway but we need a role_type
    end
  end
end
