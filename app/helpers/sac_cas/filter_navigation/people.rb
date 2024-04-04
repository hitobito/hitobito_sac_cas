# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
module SacCas::FilterNavigation::People

  TOURENLEITER_FILTERS = {
    tour_guides_active: { quali_validity: :active },
    tour_guides_stalled: { quali_validity: :not_active_but_reactivateable },
    tour_guides_inactive: { quali_validity: :active, role_kind: :inactive },
    tour_guides_none: { quali_validity: :not_active, role_kind: :inactive }
  }.freeze

  def initialize(*args)
    super

    if group.root?
      member_list = Person::Filter::NeuanmeldungenList.new(group.layer_group, template.current_user)
      item(member_list.name, template.group_people_path(group), member_list.count)
    end
  end

  private

  def add_people_filter_links
    super.tap do
      next unless group.root? || group.is_a?(Group::Sektion)

      TOURENLEITER_FILTERS.each do |key, config|
        add_tourenleiter_filter(translate(key), **config)
      end
    end
  end

  def add_tourenleiter_filter(name, role_kind: nil, quali_validity:)
    filters = { role: role_filter(role_kind), qualification: quali_filter(quali_validity) }
    dropdown.add_item(name, path(name: name, range: :deep, filters: filters))
  end

  def quali_filter(validity)
    {
      qualification_kind_ids: qualification_kind_ids.join(Person::Filter::Base::ID_URL_SEPARATOR),
      validity: validity,
      match: :one
    }
  end

  def role_filter(role_kind)
    {
      role_type_ids: Group::SektionsTourenkommission::Tourenleiter.id,
      kind: role_kind
    }.compact
  end

  def qualification_kind_ids
    @qualification_kind_ids ||= QualificationKind
      .joins(:translations)
      .where.not(validity: nil)
      .where('qualification_kind_translations.label LIKE "SAC Tourenleiter%"')
      .pluck(:id)
  end
end
