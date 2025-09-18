# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacFamilyMainPersonController < ApplicationController
  def update
    authorize!(:update, person)
    return if assert_person_household_member!

    person.household_people.each { |p| authorize!(:update, p) }
    return if assert_already_main_family_person!

    person.household.set_family_main_person!
    redirect_to person
  end

  private

  def assert_person_household_member!
    if !person.household.exists? || !person.adult? || person.email.blank?
      render plain: "Person is not associated with any household, " \
        "is not an adult or has no email address",
        status: :unprocessable_entity
    end
  end

  def assert_already_main_family_person!
    if person.sac_family_main_person?
      redirect_to person
    end
  end

  def person
    @person ||= Person.find(params[:id])
  end
end
