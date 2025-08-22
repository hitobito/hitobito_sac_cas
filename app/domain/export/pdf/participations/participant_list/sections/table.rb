# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::ParticipantList::Sections::Table < Export::Pdf::Section
  BASE_COLUMS = %w[
    member_no
    firstname
    lastname
    street
    town
    email
    phone
    language
    gender
    section
  ]

  LEADER_COLUMNS = %w[
    emergency_contact
    remarks
  ]

  def render
    data = table_data
    return if data.blank?

    pdf.table(
      data,
      header: true,
      cell_style: {
        borders: [],
        padding: [0, 3, 0, 0],
        overflow: :shrink_to_fit
      }
    ) do
      row(0).font_style = :bold
    end
  end

  def table_data
    [table_header] +
      role_types.flat_map do |type|
        entries = participations[type.sti_name.demodulize.underscore]
        next [] if entries.blank?

        rows = []
        rows += subtitle_rows(type) unless type == role_types.first
        rows + participation_rows(entries)
      end
  end

  def role_types
    [Event::Course::Role::Participant,
      Event::Course::Role::Leader,
      Event::Course::Role::LeaderAspirant,
      Event::Course::Role::AssistantLeader,
      Event::Course::Role::AssistantLeaderAspirant]
  end

  def subtitle_rows(type)
    [
      [{content: " ", colspan: BASE_COLUMS.size}],
      [content: type.model_name.human, font_style: :bold, colspan: BASE_COLUMS.size]
    ]
  end

  def participation_rows(entries)
    entries.map do |participation|
      columns = person_columns(participation.person)
      columns += leader_columns(participation) if for_leaders?
      columns
    end
  end

  def table_header
    columns = BASE_COLUMS
    columns += LEADER_COLUMNS if for_leaders?
    columns.map { |column| t(column) }
  end

  def person_columns(person)
    [
      person.id,
      person.first_name,
      person.last_name,
      person.address,
      "#{person.zip_code} #{person.town}",
      person.email,
      phone_numbers(person, %w[Privat Mobil]),
      Person::LANGUAGES[person.language&.to_sym],
      person.gender_label,
      person.sac_membership.stammsektion.to_s
    ]
  end

  def leader_columns(participation)
    [
      emergency_contact(participation),
      participation.additional_information
    ]
  end

  def phone_numbers(person, labels)
    person.phone_numbers
      .select { |phone| labels.include?(phone.label) }
      .map { |phone| phone.number }
      .sort
      .join(", ")
  end

  def emergency_contact(participation)
    participation.answers
      .select { |answer| answer.question.question.include?(t("emergency_contact")) }
      .sort_by { |answer| answer.question.question }
      .map { |answer| answer.answer }
      .join("\n")
  end

  def participations
    @participations ||=
      course.participations
        .active
        .includes(:roles, person: :phone_numbers, answers: :question)
        .order("people.last_name, people.first_name")
        .group_by { |p| p.highest_leader_role_type || "participant" }
  end

  def t(key, options = {})
    I18n.t("participations.participant_list.#{key}", **options)
  end

  def for_leaders?
    @options[:kind] == "for_leaders"
  end

  def course
    model
  end
end
