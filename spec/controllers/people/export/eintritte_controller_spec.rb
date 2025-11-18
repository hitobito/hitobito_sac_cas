# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Export::EintritteController do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  before { sign_in(user) }

  describe "POST #create" do
    it "starts export job when form is valid" do
      jobs = Delayed::Job.where("handler like '%EintritteExportJob%'")
      expect do
        post :create,
          params: {
            group_id: group,
            people_export_eintritte_form: {
              from: "1.1.2015", to: "31.12.2015"
            }
          }
      end.to change { jobs.count }.by(1)

      job = jobs.first
      expect(job.handler).to match("from: 2015-01-01")
      expect(job.handler).to match("to: 2015-12-31")
      expect(job.handler).to match("filename: 578575972_SAC-Blueemlisalp_Eintritte_20150101_20151231-")
    end

    it "returns turbo frame when form is invalid" do
      post :create,
        params: {
          group_id: group,
          people_export_eintritte_form: {
            from: "",
            to: ""
          }
        }
      expect(response.media_type).to eq Mime[:turbo_stream]
    end
  end
end
