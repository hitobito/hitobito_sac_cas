# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class LeaveZusatzsektionsController < Wizards::BaseController
    before_action :wizard, :person, :group, :role, :authorize

    helper_method :group, :person
    alias_method :entry, :wizard

    private

    def authorize
      authorize!(:create, wizard)
    end

    def wizard
      @wizard ||= model_class.new(
        person: person,
        role: role,
        current_step: params[:step].to_i,
        backoffice: person.backoffice?,
        **model_params.to_unsafe_h
      )
    end

    def model_class
      Wizards::Memberships::LeaveZusatzsektion
    end

    def success_message
      roles_count = wizard.leave_operation.affected_people.count
      t(".success", group_name: wizard.sektion, count: roles_count)
    end

    # NOTE: format: :html is required otherwise it is redirect as turbo_stream
    def redirect_target
      person_path(person, format: :html)
    end

    def person
      @person ||= Person.find(params[:person_id])
    end

    def role
      @role ||= Role.find(params[:role_id])
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
