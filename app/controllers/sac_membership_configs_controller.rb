# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacMembershipConfigsController < CrudController
  self.nesting = Group
  self.permitted_attrs =[:valid_from,
                         :sac_fee_adult,
                         :sac_fee_family,
                         :sac_fee_youth,
                         :entry_fee_adult,
                         :entry_fee_family,
                         :entry_fee_youth,
                         :hut_solidarity_fee_with_hut_adult,
                         :hut_solidarity_fee_with_hut_family,
                         :hut_solidarity_fee_with_hut_youth,
                         :hut_solidarity_fee_without_hut_adult,
                         :hut_solidarity_fee_without_hut_family,
                         :hut_solidarity_fee_without_hut_youth,
                         :magazine_fee_adult,
                         :magazine_fee_family,
                         :magazine_fee_youth,
                         :service_fee,
                         :magazine_postage_abroad,
                         :reduction_amount,
                         :reduction_required_membership_years,
                         :sac_fee_article_number,
                         :sac_entry_fee_article_number,
                         :hut_solidarity_fee_article_number,
                         :magazine_fee_article_number,
                         :section_bulletin_postage_abroad_article_number,
                         :service_fee_article_number,
                         :balancing_payment_article_number,
                         :course_fee_article_number,
                         :discount_date_1,
                         :discount_percent_1,
                         :discount_date_2,
                         :discount_percent_2,
                         :discount_date_3,
                         :discount_percent_3] 

  decorates :sac_membership_config
  helper_method :cancel_url, :available_configs

  def index
    redirect_to latest_config_entry_path
  end

  def show
    redirect_to edit_path(params[:id])
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
    SacMembershipConfig.new(attrs)
  end

  def new_entry_values
    { valid_from: Time.zone.now.year,
      discount_date_1: '1.1.',
      discount_date_2: '1.7.',
      discount_date_3: '1.10.'
    }
  end

  def find_entry
    SacMembershipConfig.find(params[:id])
  end

  def latest_config_entry_path
    if latest_config
      edit_path(latest_config.id)
    else
      new_path
    end
  end

  def edit_path(id)
    helpers.edit_group_sac_membership_config_path(group_id: Group.root.id, id: id)
  end

  def new_path
    helpers.new_group_sac_membership_config_path(group_id: Group.root.id)
  end

  def cancel_url
    group_path(id: Group.root.id)
  end

  def available_configs
    @available_configs ||= SacMembershipConfig.all.order(:valid_from)
  end

  def latest_config
    available_configs.last
  end
end
