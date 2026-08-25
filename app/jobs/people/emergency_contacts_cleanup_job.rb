# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::EmergencyContactsCleanupJob < RecurringJob
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
    Event::Participation.joins(:event)
      .where(participant_type: Person.sti_name)
      .where(events: {type: emergency_contact_event_types})
      .where(no_upcoming_event_date_exists_for_participation)
      .select(:participant_id)
  end

  def people_ids_of_current_or_future_events
    Event::Participation.joins(event: :dates)
      .where(participant_type: Person.sti_name)
      .where("event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff", cutoff: cutoff)
      .select(:participant_id)
  end

  def no_upcoming_event_date_exists_for_participation
    Event::Date.where("event_dates.event_id = events.id")
      .where("event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff", cutoff: cutoff)
      .arel.exists.not
  end

  def emergency_contact_event_types
    ([Event] + Event.descendants).select do |event_class|
      event_class.new.needs_emergency_contact?
    end.map(&:sti_name)
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
