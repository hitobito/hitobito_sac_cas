# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
module SacCas::FilterNavigation::People
  TOURENLEITER_FILTERS = {
    # `role: :active` without date range includes roles at any time, not only today
    # `role: :active_today` is a workaround to fallback on the default filter behavior
    #                       that only includes today's active roles.
    tour_guides_active: {role: :active_today},
    tour_guides_stalled: {role: :active, qualification: :not_active_but_reactivateable},
    tour_guides_inactive: {role: :inactive_but_existing, qualification: :active},
    tour_guides_none: {role: :inactive, qualification: :none},
    tour_guides_expired: {role: :active, qualification: :only_expired}
  }.freeze

  GROUPS_WITH_TOURENLEITER_FILTERS = [
    Group::SacCas,
    Group::Sektion,
    Group::Ortsgruppe
  ]

  TOURENLEITER_ROLES = [
    Group::SektionsTourenUndKurse::Tourenleiter,
    Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation
  ]

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
      next unless GROUPS_WITH_TOURENLEITER_FILTERS.any? { |klass| group.is_a?(klass) }

      TOURENLEITER_FILTERS.each do |key, config|
        add_tourenleiter_filter(translate(key), **config)
      end
    end
  end

  def add_tourenleiter_filter(name, role: nil, qualification: nil)
    filters = {role: role_filter(role), qualification: quali_filter(qualification)}
    dropdown.add_item(name, path(name: name, range: :deep, filters: filters.compact))
  end

  def quali_filter(validity)
    if validity
      {
        qualification_kind_ids: qualification_kind_ids.join(Person::Filter::Base::ID_URL_SEPARATOR),
        validity: validity,
        match: :one
      }
    end
  end

  def role_filter(role_kind)
    if role_kind
      {
        role_type_ids: TOURENLEITER_ROLES.map(&:type_id).join("-"),
        kind: role_kind
      }.compact
    end
  end

  def qualification_kind_ids
    @qualification_kind_ids ||= QualificationKind.pluck(:id)
  end
end
