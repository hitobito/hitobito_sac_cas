# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class SwitchStammsektionsController < Wizards::BaseController
    before_action :wizard, :person, :group, :authorize

    helper_method :group, :person
    alias_method :entry, :wizard

    private

    def authorize
      authorize!(:create, wizard)
    end

    def wizard
      @wizard ||= model_class.new(
        person: person,
        current_step: params[:step].to_i,
        backoffice: current_user.backoffice?,
        **model_params.to_unsafe_h
      )
    end

    def model_class
      if params[:kind] == "zusatzsektion"
        Wizards::Memberships::SwapStammZusatzsektion
      else
        Wizards::Memberships::SwitchStammsektion
      end
    end

    def success_message
      roles_count = wizard.operation.affected_people.count
      t(".success", count: roles_count, group_name: wizard.choose_sektion.group.to_s)
    end

    # NOTE: format: :html is required otherwise it is redirect as turbo_stream
    def redirect_target
      person_path(person, format: :html)
    end

    def person
      @person ||= Person.find(params[:person_id])
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
