# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::EmergencyContactsCleanupJob < RecurringJob
  EVENT_TYPES_WITH_EMERGENCY_CONTACTS = ["Event::Course", "Event::Tour"].freeze

  run_every 1.day

  def perform_internal
    return if cutoff.blank?

    Person
      .where(id: people_to_cleanup)
      .update_all(empty_emergency_contacts)
  end

  private

  def people_to_cleanup
    Person
      .where(id: people_ids_of_past_events)
      .where.not(id: people_ids_of_current_or_future_events)
  end

  def people_ids_of_past_events
    Event::Participation
      .joins(:event)
      .joins("LEFT JOIN event_kinds ON events.kind_id = event_kinds.id " \
        "LEFT JOIN event_kind_categories ON " \
        "event_kinds.kind_category_id = event_kind_categories.id")
      .where(participant_type: Person.sti_name)
      .where(events: {type: EVENT_TYPES_WITH_EMERGENCY_CONTACTS})
      .where(no_recent_event_date_exists_for_participation)
      .where(event_kind_categories: {j_s_course: [nil, false]})
      .select(:participant_id)
  end

  def people_ids_of_current_or_future_events
    Event::Participation
      .upcoming
      .where(participant_type: Person.sti_name)
      .select(:participant_id)
  end

  def no_recent_event_date_exists_for_participation
    Event::Date.where("event_dates.event_id = events.id")
      .where("event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff", cutoff: cutoff)
      .arel.exists.not
  end

  def empty_emergency_contacts
    Person::EMERGENCY_CONTACTS.to_h { |attr| [attr, nil] }
  end

  def cutoff
    @cutoff ||= begin
      duration = Settings.event.participations.delete_emergency_contacts_after_months
      duration&.months&.ago
    end
  end
end
