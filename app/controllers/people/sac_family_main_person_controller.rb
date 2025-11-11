# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacFamilyMainPersonController < ApplicationController
  before_action :authorize_update
  before_action :assert_person_household_member
  before_action :assert_already_main_family_person
  before_action :assert_user_is_not_current_main_person

  def update
    person.household.set_family_main_person!
    redirect_to person
  end

  private

  def authorize_update
    authorize!(:update, person)
    person.household_people.each { |p| authorize!(:update, p) }
  end

  def assert_person_household_member
    if !person.household.exists? || !person.adult? || person.email.blank?
      render plain: "Person is not associated with any household, " \
        "is not an adult or has no email address",
        status: :unprocessable_content
    end
  end

  def assert_already_main_family_person
    if person.sac_family_main_person?
      redirect_to person
    end
  end

  def assert_user_is_not_current_main_person
    if current_person.household_key == person.household_key &&
        current_person.sac_family_main_person?
      render plain: "You cannot transfer the main family person yourself",
        status: :unprocessable_content
    end
  end

  def person
    @person ||= Person.find(params[:id])
  end
end
