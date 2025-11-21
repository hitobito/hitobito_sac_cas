# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Migrations::UpdatePeopleConfirmedAndCorrespondenceJob do
  let(:job) { described_class.new }
  let(:migrated_at) { Time.zone.local(2024, 12, 21, 21) }
  let(:begin_of_time) { Time.zone.at(0) }

  describe "updating confirmed_at", :with_truemail_validation do
    let(:encrypted_password) { "secret" }

    it "updates person with confirmed_at=nil, valid email and encrypted password" do
      person = Fabricate(:person, confirmed_at: nil, encrypted_password: "secret")
      expect { job.perform }.to change { person.reload.confirmed_at }.to(migrated_at)
    end

    it "updates person with confirmed_at=Time.at(0), valid email and encrypted password" do
      person = Fabricate(:person, confirmed_at: begin_of_time, encrypted_password: "secret")
      expect { job.perform }.to change { person.reload.confirmed_at }.to(migrated_at)
    end

    it "does not update confirmed_at for already confirmed person" do
      person = Fabricate(:person, confirmed_at: 1.day.ago)
      expect { job.perform }.not_to change { person.reload.confirmed_at }
    end

    it "does not update confirmed_at for person with invalid email" do
      person = Fabricate(:person, confirmed_at: nil)
      person.update_column(:email, "invalid")
      expect { job.perform }.not_to change { person.reload.confirmed_at }
    end

    it "does not update confirmed_at for person without encrypted password" do
      person = Fabricate(:person, confirmed_at: nil, encrypted_password: nil)
      expect { job.perform }.not_to change { person.reload.confirmed_at }
    end
  end

  context "updating correspondence of confirmed people", versioning: true do
    it "updates correspondence from print to digital for person without any version change" do
      person = Fabricate(:person, correspondence: :print)
      expect { job.perform }.to change { person.reload.correspondence }.from("print").to("digital")
    end

    it "updates correspondence from print to digital for person with irrelevant version change" do
      person = Fabricate(:person, correspondence: :print)
      person.update!(first_name: :foobar)
      expect { job.perform }.to change { person.reload.correspondence }.from("print").to("digital")
    end

    it "noops for person with relevant version change" do
      person = Fabricate(:person, correspondence: :digital)
      person.update!(first_name: :foobar, correspondence: :print)
      expect { job.perform }.not_to change { person.reload.correspondence }
    end

    it "noops for person without relevant version change if not confirmed" do
      person = Fabricate(:person, correspondence: :print, confirmed_at: nil)
      expect { job.perform }.not_to change { person.reload.correspondence }
    end

    it "noops for person without relevant version change if confirmed at begin of time" do
      person = Fabricate(:person, correspondence: :print, confirmed_at: begin_of_time)
      expect { job.perform }.not_to change { person.reload.correspondence }
    end

    it "enqueues abacus sync job for updated person if linked" do
      abacus_client = instance_double(Invoices::Abacus::Client, "batch_context_object=": nil)
      allow(job).to receive(:abacus_client).and_return(abacus_client)

      allow(abacus_client).to receive(:batch).and_yield
      expect(abacus_client).to receive(:update).with(
        :customer,
        123,
        {subject_id: 123, customer_reminder: {dispatch_type: "Mail"}}
      ).and_return(double("res", success?: true)).once

      not_linked = Fabricate(:person, correspondence: :print)
      linked = Fabricate(:person, correspondence: :print, abacus_subject_key: "123")
      expect do
        job.perform
      end.to change { linked.reload.correspondence }
        .and change { not_linked.reload.correspondence }
    end

    it "resets confirmed_at to nil if email is blank" do
      person = Fabricate(:person, confirmed_at: migrated_at)
      person.update_column(:email, nil)
      expect { job.perform }.to change { person.reload.confirmed_at }.from(migrated_at).to(nil)
    end
  end
end
