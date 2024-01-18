# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipController < ApplicationController

  def show
    authorize!(:update, person)
    verify_membership!

    respond_to do |format|
      format.pdf do
        send_data pdf.render, type: :pdf, disposition: 'inline', filename: pdf.filename
      end
    end
  end

  private

  def verify_membership!
    not_found unless person.membership_active?
  end

  def person
    @person ||= Person.with_membership_years.find(params[:id])
  end

  def pdf
    @pdf ||= Export::Pdf::Passes::Membership.new(person)
  end

end
