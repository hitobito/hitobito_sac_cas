# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SelfInscription
  include ActiveModel::Model

  attr_accessor :register_on, :register_as

  delegate :beitragskategorie_label, to: :role

  validates :register_on, presence: true
  validates :register_as, presence: true, if: :active_member?

  def initialize(person:, group:)
    @person = person
    @group  = group

    @register_on = :now
    @register_as = :replace
  end

  def group_for_title
    role.class.name.ends_with?('::Neuanmeldung') ? @group.parent : @group
  end

  def neuanmeldung?
    @group.is_a?(Group::SektionsNeuanmeldungenSektion) ||
    @group.is_a?(Group::SektionsNeuanmeldungenNv)
  end

  def attributes=(attrs = nil)
    assign_attributes(attrs.to_h)
  end

  def register_as_options
    build_options(:register_as, register_as_keys)
  end

  def register_on_options
    build_options(:register_on, register_on_keys)
  end

  def active_member?
    sektion_membership_roles.exists?
  end

  def active_in_sektion?
    sektion_membership_roles.joins(:group).where(groups: { parent_id: @group.parent_id }).exists?
  end

  def save!
    Role.transaction do
      if future?
        save_future_role
      else
        save_role
      end
    end
  end

  private

  def register_as_keys
    active_member? ? %w(extra replace) : %w(replace)
  end

  def register_on_keys
    %w(now jul oct).reject { |key| date_from_key(key)&.past? }
  end

  def build_options(attr, list)
    list.collect { |key| [key, t("#{attr}_options", key)] }
  end

  def save_role
    active_membership_role.destroy! if replace_active_membership?
    role.save!
  end

  def save_future_role
    convert_on = date_from_key(register_on)
    active_membership_role.update!(delete_on: convert_on) if replace_active_membership?

    FutureRole.create!(
      person: role.person,
      group: role.group,
      convert_to: role.type,
      convert_on: convert_on
    )
  end

  def date_from_key(key)
    index = Date::ABBR_MONTHNAMES.index(key.to_s.capitalize)
    Date.new(today.year, index) if index
  end

  def replace_active_membership?
    active_member? && register_as.match(/replace/)
  end

  def active_membership_role
    @active_membership_role ||= sektion_membership_roles.find_by(group_id: @person.primary_group_id)
  end

  def sektion_membership_roles
    role.person.roles.where(type: Group::SektionsMitglieder::Mitglied.sti_name)
  end

  def future?
    !/now/.match(register_on)
  end

  def role
    @role ||= role_type.new(
      group: @group,
      person: @person,
      # TODO: in a later ticket: what values should we set for the timestamps?
      created_at: Time.zone.now,
      delete_on: Time.zone.today.end_of_year
    ).tap(&:valid?)
  end

  def role_type
    @group.self_registration_role_type.constantize
  end

  def today
    @today ||= Time.zone.today
  end

  def t(*keys)
    I18n.t(keys.join('.'), scope: 'activemodel.attributes.self_inscription')
  end
end
