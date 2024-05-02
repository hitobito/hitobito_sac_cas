# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacMembershipConfigs
  class ValidFromSelectorComponent < ApplicationComponent

    delegate :entry, to: :helpers

    def initialize(group, available_configs)
      @group = group
      @available_configs = available_configs
    end

    private

    def item_class(config)
      'active' if active?(config)
    end

    def new_item_class
      'active' if entry.new_record?
    end

    def active?(config)
      config.id == params[:id].to_i
    end

    def link_to_edit_config(config)
      link_to(config.valid_from,
              polymorphic_path([@group, config], action: :edit),
              class: 'page-link')
    end

    def link_new_config
      link_to(t('sac_section_membership_configs.global.link.add'),
              polymorphic_path([@group, entry.class], action: :new),
              class: 'page-link')
    end

  end
end
