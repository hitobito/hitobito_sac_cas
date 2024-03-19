# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe MailingList do
  context 'seeded data' do
    def newsletter
      MailingList.find_by(internal_key: SacCas::NEWSLETTER_MAILING_LIST_INTERNAL_KEY)
    end

    it 'has newsletter mailing list' do
      expect(newsletter).not_to be_present
      MailingListSeeder.seed!
      expect(newsletter).to be_present

    end

    it 'has newsletter mailing list subscription' do
      MailingListSeeder.seed!
      expect(newsletter.subscriptions).to contain_exactly(
        have_attributes(
          subscriber_id: Group.root.id,
          subscriber_type: Group.sti_name,
          related_role_types: contain_exactly(
            have_attributes(role_type: Group::SektionsMitglieder::Mitglied.sti_name),
            have_attributes(role_type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name),
            have_attributes(role_type: Group::SektionsMitglieder::Ehrenmitglied.sti_name),
            have_attributes(role_type: Group::SektionsMitglieder::Beguenstigt.sti_name),
            have_attributes(role_type: Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name),
            have_attributes(role_type: Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name),
            have_attributes(role_type: Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name),
            have_attributes(role_type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name),
            have_attributes(role_type: Group::AboTourenPortal::Abonnent.sti_name),
            have_attributes(role_type: Group::AboTourenPortal::Neuanmeldung.sti_name),
            have_attributes(role_type: Group::AboMagazin::Abonnent.sti_name),
            have_attributes(role_type: Group::AboMagazin::Neuanmeldung.sti_name),
            have_attributes(role_type: Group::AboBasicLogin::BasicLogin.sti_name)
          )
        )
      )
    end
  end
end
