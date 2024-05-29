# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacFamilyMainPersonController < ApplicationController
  def update
    authorize!(:update, person)

    unless person.sac_family_member?
      return render plain: 'Person is not associated with any household',
                    status: :unprocessable_entity
    end

    authorize!(:set_sac_family_main_person, person)

    if person.sac_family_main_person
      return redirect_to person
    end

    person.sac_family.set_family_main_person
    redirect_to person
  end

  private

  def person
    @person ||= Person.find(params[:id])
  end
end
