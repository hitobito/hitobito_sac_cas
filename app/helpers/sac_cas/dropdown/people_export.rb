# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Dropdown::PeopleExport
  def tabular_links(format)
    super.tap do |item|
      item.sub_items << Dropdown::Item.new(translate(:recipients),
        params.merge(format: format, recipients: true),
        data: {checkable: true})
      item.sub_items << Dropdown::Item.new(translate(:recipient_households),
        params.merge(format: format, recipient_households: true),
        data: {checkable: true})
    end
  end

  # original method in youth wagon
  def is_course?(event)
    event.course?
  end

  # original method in youth wagon
  def add_course_items(item, path)
    super

    item.sub_items << Dropdown::Item.new(translate(:course_data),
      path.merge(course_data: true),
      data: {checkable: true})
  end

  def pdf_link
    if participation_lists?
      item = add_item(translate(:pdf), "#")
      item.sub_items <<
        adresslist_pdf_item <<
        list_for_participants_pdf_item <<
        list_for_leaders_pdf_item
      item
    else
      super
    end
  end

  def adresslist_pdf_item
    pdf_item(:adress_list)
  end

  def list_for_participants_pdf_item
    pdf_item(:list_for_participants, list_kind: "for_participants")
  end

  def list_for_leaders_pdf_item
    pdf_item(:list_for_leaders, list_kind: "for_leaders")
  end

  def pdf_item(label_key, additional_params = {})
    Dropdown::Item.new(
      translate(label_key),
      params.merge(additional_params).merge(format: :pdf),
      data: {checkable: true},
      target: :_blank
    )
  end

  def participation_lists?
    @details &&
      params[:controller] == "event/participations" &&
      template.entry.event.course?
  end
end
