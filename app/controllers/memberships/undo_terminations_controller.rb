# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class UndoTerminationsController < ApplicationController
    before_action :authorize, :role, :person, :group

    def new
      @undo_termination = UndoTermination.new(role).tap(&:validate)
    end

    def create
      @undo_termination = UndoTermination.new(role)
      if @undo_termination.valid?
        @undo_termination.save!
        redirect_to group_person_path(role.person, group_id: role.group_id)
      else
        render :new
      end
    end

    private

    def authorize
      authorize!(:create, UndoTermination)
    end

    def role
      @role ||= Role.with_inactive.find(params[:role_id])
    end

    def person
      @person ||= Person.find(params[:person_id])
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
