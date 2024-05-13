# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacMembershipConfigs
  class ValidFromSelectorComponent < ApplicationComponent

    def initialize(entry:, available_configs:)
      @entry = entry
      @available_configs = available_configs
    end

    private

    def active?(config)
      config.id == params[:id].to_i
    end

    def link_to_edit_config(config)
      link_to(config.valid_from,
              edit_group_sac_membership_config_path(group_id: Group.root.id, id: config.id),
              class: 'page-link')
    end

    def link_new_config
      link_to(t('sac_membership_configs.global.link.add'),
              new_group_sac_membership_config_path(group_id: Group.root.id),
              class: 'page-link')
    end

  end
end
