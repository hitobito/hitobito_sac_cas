# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::Participations::CourseDataRow < Export::Tabular::Row
  self.dynamic_attributes = {
    /^event_/ => :event_attribute,
    /^person_/ => :person_attribute
  }

  def event_attribute(event_attr)
    attr = event_attr.to_s.split("_", 2)[1]
    if respond_to?(event_attr, true)
      send(event_attr)
    else
      event.send(attr)
    end
  end

  def person_attribute(person_attr)
    attr = person_attr.to_s.split("_", 2)[1]
    if respond_to?(person_attr, true)
      send(person_attr)
    else
      person.send(attr)
    end
  end

  def value_for(attr)
    I18n.with_locale(event_i18n_language) do
      super
    end
  end

  def event_dates_locations = event.dates.pluck(:location).uniq.join(", ")

  def event_first_date = event.dates.order(start_at: :asc).first.start_at

  def event_last_date = event.dates.order(finish_at: :asc).last.finish_at

  def person_gender = person.gender_label

  def person_language_code = [person.language.upcase, "S"].join

  def person_stammsektion = [stammsektion&.id, stammsektion&.name].join(" ")

  def person = @person ||= @entry.person

  def event = @event ||= @entry.event

  def stammsektion = @stammsektion ||= person.primary_group&.layer_group

  def event_i18n_language
    {
      de: :de,
      de_fr: :de,
      fr: :fr,
      it: :it
    }[event.language.to_sym]
  end
end
