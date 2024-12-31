# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class LeaveZusatzsektion
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations
    include CommonApi

    validate :assert_terminate_on

    ROLE_TYPES = [
      Group::SektionsMitglieder::MitgliedZusatzsektion,
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation,
      Group::SektionsTourenUndKurse::Tourenleiter
    ]

    attribute :termination_reason_id, :integer

    validates :termination_reason_id, presence: true

    delegate :person, :group, to: :role

    def initialize(role, terminate_on, **params)
      super(params)
      @role = role
      @terminate_on = terminate_on
      @now = Time.zone.now

      raise "wrong type" if bad_role_type?
      raise "not main family person" if bad_family?
    end

    private

    def roles
      @roles ||= find_roles_in_layer.each do |role|
        set_termination_date(role)
      end
    end

    def find_roles_in_layer
      Role
        .joins(:group)
        .where(
          type: ROLE_TYPES.map(&:sti_name),
          person: affected_people,
          groups: {layer_group_id: group.layer_group_id}
        )
    end

    def end_on(role)
      # when selecting leave zusatzsektion right now, terminate_on will be yesterday, not today!
      # resulting in that case always executing the else block
      unless terminate_on.past?
        [role.end_on, terminate_on].compact.min
      else
        now.to_date.yesterday
      end
    end

    def set_termination_date(role) # rubocop:disable Naming/AccessorMethodName
      role.termination_reason_id = termination_reason_id

      role_end_on = end_on(role)
      return role.mark_for_destruction if role_end_on < role.start_on

      role.end_on = role_end_on
      role.write_attribute(:terminated, true)
    end

    def bad_role_type?
      role.type != "Group::SektionsMitglieder::MitgliedZusatzsektion"
    end

    def bad_family?
      role.beitragskategorie&.family? && !person.sac_family_main_person
    end

    def assert_terminate_on
      valid_dates = [now.yesterday.to_date, now.end_of_year.to_date]
      unless valid_dates.include?(terminate_on)
        errors.add(:terminate_on, :invalid)
      end
    end

    attr_reader :terminate_on, :role, :now
  end
end
