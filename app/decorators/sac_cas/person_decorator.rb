# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonDecorator
  extend ActiveSupport::Concern

  def login_status_icons
    {wso2_legacy_password: "user-check"}.merge(super)
  end

  def as_typeahead
    {id: id, label: h.h(full_label_with_changed_suffix)}
  end

  def roles_for_oauth
    object.roles.includes(group: :layer_group).collect(&:decorate).collect(&:for_oauth)
  end

  def as_quicksearch
    super.tap do |data|
      data[:label] = h.h(full_label_with_changed_suffix)
    end
  end

  private

  def login_status_icon_options(login_status)
    if login_status == :wso2_legacy_password
      super.merge(class: "text-warning")
    else
      super
    end
  end

  def full_label_with_changed_suffix
    suffix = [model.birthday&.year, model.id].compact.join("; ")

    to_s.tap do |label|
      label << ", #{town}" if town?
      label << " (#{full_name})" if company? && full_name.present?
      label << " (#{suffix})"
    end
  end
end
