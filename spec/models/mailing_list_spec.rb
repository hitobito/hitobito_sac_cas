# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MailingList do
  context "seeded data" do
    def newsletter
      MailingList.find_by(internal_key: SacCas::MAILING_LIST_SAC_NEWSLETTER_INTERNAL_KEY)
    end

    it "has newsletter mailing list" do
      expect(newsletter).not_to be_present
      MailingListSeeder.seed!
      expect(newsletter).to be_present
      expect(newsletter.subscribable_for).to eq("configured")
      expect(newsletter.subscribable_mode).to eq("opt_in")
      expect(newsletter.filter_chain.to_hash).to be_blank
    end

    it "has newsletter mailing list subscription" do
      MailingListSeeder.seed!
      expect(newsletter.subscriptions).to contain_exactly(
        have_attributes(
          subscriber_id: Group.root.id,
          subscriber_type: Group.sti_name
        )
      )

      sub = newsletter.subscriptions.first
      expect(sub.role_types).to contain_exactly(
        Group::SektionsMitglieder::Mitglied.sti_name,
        Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name,
        Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
        Group::AboTourenPortal::Abonnent.sti_name,
        Group::AboTourenPortal::Gratisabonnent.sti_name,
        Group::AboMagazin::Abonnent.sti_name,
        Group::AboMagazin::Gratisabonnent.sti_name,
        Group::AboMagazin::Neuanmeldung.sti_name,
        Group::AboBasicLogin::BasicLogin.sti_name
      )
    end
  end
end
