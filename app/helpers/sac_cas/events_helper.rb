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

  # main entries are optgroups and not selectable
  def tour_essentials_grouped_select_options(entries)
    entries.select(&:main?).flat_map do |main|
      entries.select { |d| d.parent_id == main.id }.map do |child|
        {id: child.id, label: child.to_s, description: child.short_description, group: main.id}
      end
    end.to_json
  end

  def tour_essentials_grouped_select_optgroups(entries, color: false)
    entries.select(&:main?).flat_map do |main|
      color = main.color if color
      {value: main.id, label: main.to_s, color:}.compact_blank
    end.to_json
  end

  # main entries are regular selectable options
  def tour_essentials_nested_select_options(entries)
    entries.select(&:main?).flat_map do |main|
      [{id: main.id, label: main.to_s, description: main.short_description}] +
        entries.select { |d| d.parent_id == main.id }.map do |child|
          {id: child.id,
           label: "    #{child}",
           description: child.short_description.present? ? "     #{child.short_description}" : nil}
        end
    end.to_json
  end

  def tour_essentials_opt_group_header_with_color
    <<~JS
      return function(data) {
        if (!data.color) {
          return `<div class="optgroup-header">${data.label}</div>`;
        }
        return `<div class="optgroup-header">
                  <i style="color: ${data.color}" class="fas fa-circle"></i>
                  <span class="ms-1">${data.label}</span>
                </div>`;
      }
    JS
  end

  def fitness_requirements_select_options(requirements)
    requirements.map do |entry|
      {id: entry.id, label: entry.to_s, description: entry.short_description}
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

  def format_event_fitness_requirement(event)
    render_event_essential(event.fitness_requirement) if event.fitness_requirement
  end

  def format_event_technical_requirements(event)
    event_essentials_list(event.technical_requirements, wrap_children: false, separator: ": ")
  end

  def format_event_traits(event)
    safe_join(event.traits.sort_by(&:label), ", ") { |t| render_event_essential(t) }
  end

  def event_essentials_list(association, wrap_children: true, separator: " ")
    simple_list(event_essentials_with_children(association), class: "mb-0") do |main, children|
      parent = render_event_essential(main)
      if children.present?
        child_list = safe_join(children, ", ") { |c| render_event_essential(c) }
        child_list = wrap_children ? safe_join(["(", child_list, ")"]) : child_list
        safe_join([parent, child_list], separator)
      else
        parent
      end
    end
  end

  private

  def event_essentials_with_children(association)
    entries = association.list.includes(:parent).group_by(&:parent)
    main = entries.keys.compact + entries.fetch(nil, [])
    main.uniq.sort_by(&:order).map do |parent|
      [parent, entries[parent]]
    end
  end

  def render_event_essential(entry)
    if entry.description.present?
      with_tooltip(entry.label, entry.description)
    else
      entry.label
    end
  end
end
