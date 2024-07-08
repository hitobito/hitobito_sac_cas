# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Person::SacRemarksController < ApplicationController
  helper_method :person, :group, :remark_attr_name, :available_attrs
  before_action :authorize_action, except: :index
  before_action :group, only: :index

  def index
    authorize! :show_remarks, person
  end

  def update
    if person.update(permitted_attr)
      respond_to do |format|
        format.html do
          render "_remark", layout: false, locals: {remark_attr_name: remark_attr_name}
        end
      end
    else
      render :edit
    end
  end

  private

  def group
    @group ||= Group.find params[:group_id]
  end

  def person
    @person ||= Person.find params[:person_id]
  end

  def remark_attr_name
    @remark_attr_name ||= params[:id]
  end

  def available_attrs
    @available_attrs ||= fetch_available_attrs
  end

  def fetch_available_attrs
    @available_attrs = []
    @available_attrs << Person::SAC_REMARK_NATIONAL_OFFICE if can?(:manage_national_office_remark,
      person)
    @available_attrs += Person::SAC_SECTION_REMARKS if can?(:manage_section_remarks, person)
    @available_attrs
  end

  def permitted_attr
    params.require(:person).permit remark_attr_name
  end

  def authorize_action
    if remark_attr_name.eql?(Person::SAC_REMARK_NATIONAL_OFFICE)
      authorize! :manage_national_office_remark, person
    elsif Person::SAC_SECTION_REMARKS.include?(remark_attr_name)
      authorize! :manage_section_remarks, person
    else
      raise CanCan::AccessDenied
    end
  end
end
