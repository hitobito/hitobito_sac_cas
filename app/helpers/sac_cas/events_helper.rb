# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::EventsHelper
  def format_event_application_conditions(entry)
    if entry.application_conditions.present?
      safe_auto_link(entry.application_conditions, html: {target: "_blank"})
    end
  end

  def format_event_unconfirmed_count(event)
    if event.unconfirmed_count.positive? && can?(:application_market, event)
      badge(event.unconfirmed_count, :secondary)
    end
  end

  def disciplines_select_options(main_disciplines)
    main_disciplines.flat_map do |main|
      main.children.sort_by(&:order).map do |child|
        {id: child.id, label: child.to_s, description: child.short_description, group: main.id}
      end
    end.to_json
  end

  def disciplines_select_optgroups(main_disciplines)
    main_disciplines.flat_map do |main|
      {value: main.id, label: main.to_s}
    end.to_json
  end

  def target_groups_select_options(main_groups)
    main_groups.flat_map do |main|
      [{id: main.id, label: main.to_s, description: main.short_description}] +
        main.children.sort_by(&:order).map do |child|
          {id: child.id,
           label: "    #{child}",
           description: child.short_description.present? ? "     #{child.short_description}" : nil}
        end
    end.to_json
  end

  def price_category_label(entry, attr)
    if entry&.kind&.kind_category&.j_s_course
      I18n.t("activerecord.attributes.event/course.j_s_#{attr}")
    else
      I18n.t("activerecord.attributes.event/course.#{attr}")
    end
  end

  def format_event_disciplines(event)
    event_essentials_list(event.disciplines)
  end

  def format_event_target_groups(event)
    event_essentials_list(event.target_groups)
  end

  def event_essentials_list(association, wrap_children: true, separator: " ")
    simple_list(event_essentials_with_children(association), class: "mb-0") do |main, children|
      parent = with_tooltip(main.label, main.description)
      if children.present?
        child_list = safe_join(children, ", ") { |c| with_tooltip(c.label, c.description) }
        child_list = wrap_children ? safe_join(["(", child_list, ")"]) : child_list
        safe_join([parent, child_list], separator)
      else
        parent
      end
    end
  end

  private

  def event_essentials_with_children(association)
    entries = association.with_deleted.list.includes(:parent).group_by(&:parent)
    main = entries.keys.compact + entries.fetch(nil, [])
    main.uniq.sort_by(&:order).map do |parent|
      [parent, entries[parent]]
    end
  end
end
