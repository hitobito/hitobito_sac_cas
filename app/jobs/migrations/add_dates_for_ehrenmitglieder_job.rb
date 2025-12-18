# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  class AddDatesForEhrenmitgliederJob < BaseJob
    def perform
      PaperTrail.request.whodunnit = "Add Dates For Ehrenmitglieder Job"
      PaperTrail.request.controller_info = {mutation_id: SecureRandom.uuid}

      relevant_roles.find_each(batch_size: 100) do |role|
        next if role.valid?

        changes = role_changes(role)
        role.update(changes) if changes.present?
      end
    end

    def role_changes(role)
      dates = group_membership_dates(role)
      return {} unless dates

      changes = {}
      if !role.start_on || role.start_on < dates.first
        changes[:start_on] = dates.first
      end
      if !role.end_on || role.end_on > dates.last
        changes[:end_on] = dates.last
      end
      changes
    end

    def group_membership_dates(role) # rubocop:disable Metrics/CyclomaticComplexity
      first_without_gap = nil
      last_without_gap = nil
      previous = nil
      fetch_memberships(membership_condition(role)).each do |membership|
        if !role.end_on || membership.start_on <= role.end_on
          last_without_gap = membership
          if previous.nil? || membership.start_on > previous.end_on + 1.day
            first_without_gap = membership
          end
        end
        previous = membership
      end
      first_without_gap ? first_without_gap.start_on..last_without_gap.end_on : nil
    end

    def membership_condition(role)
      if role.is_a?(Group::Ehrenmitglieder::Ehrenmitglied)
        {person_id: role.person_id}
      else
        {person_id: role.person_id, group_id: role.group_id}
      end
    end

    def fetch_memberships(condition)
      Role
        .with_inactive
        .where(type: SacCas::MITGLIED_ROLES.map(&:sti_name))
        .where(condition)
        .order(:start_on)
    end

    def relevant_roles
      Role.unscoped.where(type: SacCas::MEMBERSHIP_PROLONGABLE_ROLES.map(&:sti_name))
    end
  end
end
