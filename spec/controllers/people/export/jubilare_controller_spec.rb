# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Export::JubilareController do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  before { sign_in(user) }

  describe "POST #create" do
    it "starts export job when form is valid" do
      jobs = Delayed::Job.where("handler like '%JubilareExportJob%'")
      expect do
        post :create,
          params: {
            group_id: group,
            people_export_jubilare_form: {
              reference_date: "1.10.2025", membership_years: 20
            }
          }
      end.to change { jobs.count }.by(1)

      job = jobs.first
      expect(job.handler).to match("reference_date: 2025-10-01")
      expect(job.handler).to match("membership_years: 20")
      expect(job.handler).to match("filename: 578575972_SAC-Blueemlisalp_Jubilare_per_20251001-")
    end

    it "returns turbo frame when form is invalid" do
      post :create,
        params: {
          group_id: group,
          people_export_jubilare_form: {
            reference_date: ""
          }
        }
      expect(response.media_type).to eq Mime[:turbo_stream]
    end
  end
end
