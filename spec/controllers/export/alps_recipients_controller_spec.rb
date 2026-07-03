# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::AlpsRecipientsController do
  let(:user) { people(:admin) }
  let(:group) { groups(:root) }

  before { sign_in(user) }

  describe "POST #create" do
    it "starts export job when form is valid" do
      jobs = Delayed::Job.where("handler like '%AlpsRecipientsExportJob%'")
      expect do
        post :create,
          params: {
            group_id: group,
            people_export_alps_recipients_form: {
              reference_date: "1.5.2025",
              new_entries_from: "1.1.2025"
            }
          }
        expect(response).to redirect_to(group_path(group))
      end.to change { jobs.count }.by(1)

      job = jobs.first
      expect(job.handler).to match("reference_date: 2025-05-01")
      expect(job.handler).to match("new_entries_from: 2025-01-01")
      expect(job.handler).to match("filename: Die_Alpen_Empfängerlisten_20250501-")
    end

    it "returns turbo frame when form is invalid" do
      post :create,
        params: {
          group_id: group,
          people_export_alps_recipients_form: {
            reference_date: "",
            new_entries_from: "1.1.2025"
          }
        }
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(response.status).to eq(422)
    end
  end
end
