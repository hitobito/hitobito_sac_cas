# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class TerminateSacMembershipsController < Wizards::BaseController
    before_action :wizard, :person, :group, :authorize

    helper_method :group, :person
    alias_method :entry, :wizard

    private

    def authorize
      authorize!(:terminate, wizard.role)
    end

    def wizard
      @wizard ||= model_class.new(
        person: person,
        current_step: params[:step].to_i,
        backoffice: current_user != person,
        **model_params.to_unsafe_h
      )
    end

    def model_class
      Wizards::Memberships::TerminateSacMembershipWizard
    end

    def success_message
      roles_count = wizard.terminate_operation.affected_people.count
      t(".success", group_name: wizard.sektion_name, count: roles_count)
    end

    # NOTE: format: :html is required otherwise it is redirect as turbo_stream
    def redirect_target
      # if the current_user does not have the ability to show the person in other groups the person has (or will have) roles 
      # in, we redirect to the member list and display the flash message there
      if can?(:show, entry)
        person_path(person, format: :html)
      else
        group_people_path(group, format: :html)
      end
    end

    def person
      @person ||= Person.find(params[:person_id])
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
