# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module MembershipConfigurable
  extend ActiveSupport::Concern

  included do
    helper_method :cancel_url, :available_configs, :group
    before_action :assert_group_type
  end

  def index
    redirect_to latest_config_entry_path
  end

  def show
    redirect_to edit_path(find_entry)
  end

  private

  def build_entry
    if latest_config
      attrs = latest_config.attributes
      attrs.delete('id')
      attrs[:valid_from] = latest_config.valid_from + 1
    else
      attrs = new_entry_values
    end
    model_class.new(attrs)
  end

  def latest_config_entry_path
    if latest_config
      edit_path(latest_config)
    else
      new_path
    end
  end

  def find_entry
    group_configs.find(params[:id])
  end

  def edit_path(config)
    polymorphic_path([group, config], action: :edit)
  end

  def new_path
    polymorphic_path([group, model_class], action: :new)
  end

  def cancel_url
    group_path(id: group.id)
  end

  def available_configs
    @available_configs ||= group_configs.list.to_a
  end

  def group_configs
    model_class.all
  end

  def latest_config
    available_configs.last
  end

end
