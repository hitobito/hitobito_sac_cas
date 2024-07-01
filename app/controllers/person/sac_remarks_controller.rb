# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Person::SacRemarksController < ApplicationController
  before_action :entry
  before_action :authorize_action, except: :index

  def index
    authorize! :show_remarks, @person
  end

  def update
    if @person.update permitted_params
      respond_to do |format|
        format.html { render '_remark', layout: false, locals: { remark_attr: @remark_attr } }
      end
    else
      render :edit
    end
  end

  private

  def entry
    @group ||= group
    @person ||= person
    @remark_attr ||= params[:id]
  end

  def group
    Group.find params[:group_id]
  end

  def person
    Person.find params[:person_id]
  end

  def permitted_params
    params.require(:person).permit @remark_attr
  end

  def authorize_action
    if @remark_attr.eql? Person::SAC_REMARKS.first
      authorize! :manage_national_office_remark, @person
    else
      authorize! :manage_section_remarks, @person
    end
  end
end
