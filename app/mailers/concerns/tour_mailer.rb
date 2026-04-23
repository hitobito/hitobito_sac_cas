# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module TourMailer
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  # this class is only a placeholder for the custom content keys.
  # move the keys once the actual mailers for them are implemented.
  PUBLICATION = "event_tour_publication"
  PUBLICATION_SUBITO = "event_tour_subito_publication"
  PARTICIPATION_SUMMON = "event_tour_participation_summon"
  PARTICIPATION_REJECT = "event_tour_participation_reject"
  CLOSING = "event_tour_closing"
  CANCELED_MINIMUM_PARTICIPANTS = "event_tour_canceled_minimum_participants"
  CANCELED_NO_LEADER = "event_tour_canceled_no_leader"
  CANCELED_WEATHER = "event_tour_canceled_weather"
  BACK_TO_DRAFT = "event_tour_back_to_draft"
  BACK_TO_APPROVED = "event_tour_back_to_approved"
  BACK_TO_PUBLISHED = "event_tour_back_to_published"
  BACK_TO_READY = "event_tour_back_to_ready"

  private

  [:id, :first_name, :last_name, :email].each do |attr|
    define_method :"placeholder_recipient_#{attr}" do
      @person.public_send(attr)
    end

    define_method :"placeholder_contact_#{attr}" do
      @event.contact&.public_send(attr)
    end

    define_method :"placeholder_updater_#{attr}" do
      @event.updater&.public_send(attr)
    end
  end

  def placeholder_recipient_link
    link_to(person_url(@person))
  end

  def placeholder_contact_phone
    placeholder_phone_value(@event.contact)
  end

  def placeholder_updater_phone
    placeholder_phone_value(@event.updater)
  end

  def placeholder_phone_value(person)
    return unless person

    person.phone_number_mobile&.value&.presence ||
      person.phone_number_landline&.value
  end

  def placeholder_participation_link
    link_to(
      t(:application),
      group_event_participation_url(
        group_id: @event.group_ids.first,
        event_id: @event.id,
        id: @participation.id
      )
    )
  end

  def placeholder_participation_additional_information
    labeled_text_attr(@participation, :additional_information, t(:none))
  end

  def placeholder_participation_answers
    answers = @participation.answers.list.where(event_questions: {admin: false}).to_a
    if answers.present?
      label = Event::Participation.human_attribute_name(:answers)
      text = answers.map do |a|
        q = a.question.question.strip
        q += ":" unless q.end_with?(":", "?", ".", "!")
        "#{q} #{a.answer}"
      end
      labeled(label, join_lines(text))
    end
  end

  def placeholder_event_name
    @event.name
  end

  def placeholder_event_id
    @event.id
  end

  def placeholder_event_link
    link_to(
      @event.name,
      group_event_url(group_id: @event.group_ids.first, id: @event.id)
    )
  end

  def placeholder_event_dates
    join_lines([
      labeled_event_dates,
      labeled_event_application_dates,
      labeled_ics_link
    ].compact, "\n")
  end

  def labeled_event_dates
    label = Event.human_attribute_name(:dates)
    value = join_lines(@event.dates.map(&:to_s))
    labeled(label, value)
  end

  def labeled_event_application_dates
    return if !@event.application_opening_at && !@event.application_closing_at

    label = t(:application_window)
    value = Duration.new(@event.application_opening_at, @event.application_closing_at).to_s
    labeled(label, value)
  end

  def labeled_ics_link
    label = t(:ics_link)
    url = group_event_url(group_id: @event.group_ids.first, id: @event.id, format: :ics)
    value = link_to(t(:download_ics), url)
    labeled(label, value)
  end

  def placeholder_event_essentials
    target_groups = load_essentials(:target_groups)
    disciplines = load_essentials(:disciplines)
    join_lines([
      labeled_main_target_groups(target_groups),
      labeled_sub_target_groups(target_groups),
      labeled_main_disciplines(disciplines),
      labeled_sub_disciplines(disciplines),
      labeled_traits
    ].compact, "\n")
  end

  def placeholder_event_requirements
    join_lines([
      labeled_fitness_requirement,
      labeled_technical_requirements
    ].compact, "\n")
  end

  def labeled_main_target_groups(target_groups)
    labeled_main_essentials(target_groups, :target_groups)
  end

  def labeled_sub_target_groups(target_groups)
    labeled_sub_essentials(target_groups, :sub_target_groups)
  end

  def labeled_main_disciplines(disciplines)
    labeled_main_essentials(disciplines, :disciplines)
  end

  def labeled_sub_disciplines(disciplines)
    labeled_sub_essentials(disciplines, :sub_disciplines)
  end

  def labeled_traits
    labeled_sub_essentials(load_essentials(:traits), :traits)
  end

  def labeled_fitness_requirement
    return unless @event.fitness_requirement

    label = Event::Tour.human_attribute_name(:fitness_requirement)
    labeled(label, @event.fitness_requirement.to_s)
  end

  def labeled_technical_requirements
    labeled_sub_essentials(load_essentials(:technical_requirements), :technical_requirements)
  end

  def labeled_main_essentials(list, label_key)
    return if list.blank?

    label = Event::Tour.human_attribute_name(label_key)
    value = list.map { |t| t.parent || t }.uniq.sort_by(&:order).map(&:to_s).join(", ")
    labeled(label, value)
  end

  def labeled_sub_essentials(list, label_key)
    sub_list = list.select(&:parent)
    return if sub_list.blank?

    value = sub_list.sort_by { |t| [t.parent.order, t.order] }.map(&:to_s).join(", ")
    labeled(t(label_key), value)
  end

  def load_essentials(assoc)
    @event.public_send(assoc).includes(:translations, parent: :translations).to_a
  end

  def placeholder_event_details
    join_lines([
      labeled_text_attr(@event, :description),
      labeled_text_attr(@event, :additional_info)
    ].compact, "\n")
  end

  def placeholder_event_attachments
    list = @event.attachments.visible_for_participants.list.map do |attachment|
      link_to(attachment.to_s, attachment.file.url)
    end

    labeled(t(:attachments), list.present? ? join_lines(list) : t(:no_attachments))
  end

  def placeholder_event_internal_comment
    labeled_text_attr(@event, :internal_comment, t(:none))
  end

  def placeholder_section_name
    @group.name
  end

  def labeled_text_attr(model, attr, default = nil)
    label = model.class.human_attribute_name(attr)
    value = model.send(attr)
    return if value.blank? && default.nil?

    value = value.present? ? convert_newlines_to_breaks(value) : default
    labeled(label, escape_html(value))
  end

  def labeled(label, value)
    "<dl><dt>#{label}</dt><dd>#{value}</dd></dl>".html_safe
  end

  def t(key)
    I18n.t("event.tour_mailer.#{key}")
  end
end
