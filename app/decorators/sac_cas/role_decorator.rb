# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::RoleDecorator
  extend ActiveSupport::Concern

  def for_oauth
    {
      **super,
      layer_group_id: object.group.layer_group.id,
      layer_group_name: object.group.layer_group.name
    }
  end

  def name_with_group_and_layer
    "#{role.group.layer_group} / #{role.group}: #{role}"
  end

  def name_with_group_and_period
    "#{role.group} #{formatted_name(strong: true, show_end_on: true, show_start_on: true)}"
      .html_safe
  end
end
