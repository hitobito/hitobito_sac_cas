# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_swb.

require "spec_helper"

describe Devise::ConfirmationsController do
  let(:person) { people(:mitglied) }

  let(:transmit_jobs) { Delayed::Job.where("handler ILIKE '%Abacus::TransmitPersonJob%'") }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:person]
  end

  it "enqueues transmit job when confirming email" do
    person.update!(unconfirmed_email: "dummy@example.com", confirmation_token: "ab", correspondence: :print)
    transmit_jobs.destroy_all

    expect do
      get :show, params: {confirmation_token: "ab"}
    end.to change { person.reload.email }.from("e.hillary@hitobito.example.com").to("dummy@example.com")
      .and change { transmit_jobs.count }.by(1)
  end
end
