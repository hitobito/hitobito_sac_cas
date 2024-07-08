# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SubscriptionsController do
  let(:user) { people(:admin) }
  let(:mailing_list) { mailing_lists(:newsletter) }

  before { sign_in(user) }

  context "GET index" do
    context "with format=csv and param recipients=true" do
      it "calls ... with ..." do
        expect do
          get :index, params: {
            format: :csv,
            group_id: mailing_list.group_id,
            mailing_list_id: mailing_list.id,
            recipients: true
          }
          expect(response).to be_redirect
        end.to change { Delayed::Job.count }.by(1)

        job = Delayed::Job.last.payload_object
        expect(job).to be_a(Export::SubscriptionsJob)

        expect(Export::Tabular::People::SacRecipients)
          .to receive(:export)
        job.perform
      end
    end
  end
end
