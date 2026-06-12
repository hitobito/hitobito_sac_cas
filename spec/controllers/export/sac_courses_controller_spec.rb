# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::SacCoursesController do
  let(:user) { people(:admin) }
  let(:group) { groups(:root) }

  before { sign_in(user) }

  describe "POST #create" do
    it "starts export job when form is valid" do
      jobs = Delayed::Job.where("handler like '%SacCoursesExportJob%'")
      expect do
        post :create,
          params: {
            group_id: group,
            export: {
              year: "2025"
            }
          }
      end.to change { jobs.count }.by(1)

      job = jobs.first
      expect(job.handler).to match("year: 2025")
      expect(job.handler).to match("filename: SAC_Finanzindikatoren_Kurse_2025-")
    end
  end
end
