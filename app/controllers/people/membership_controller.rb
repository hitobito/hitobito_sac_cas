# frozen_string_literal: true

#  Copyright (c) 2023-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::MembershipController < ApplicationController
  def show
    authorize!(:show, person)

    if person.membership_pass
      redirect_to group_person_pass_path(person.default_group_id, person, person.membership_pass)
    else
      redirect_to person_path(person)
    end
  end

  private

  def person
    @person ||= Person.find(params[:id])
  end
end
