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

    def sac_inside
      MailingList.find_by(internal_key: SacCas::MAILING_LIST_SAC_INSIDE_INTERNAL_KEY)
    end

    def tourenleiter
      MailingList.find_by(internal_key: SacCas::MAILING_LIST_TOURENLEITER_INTERNAL_KEY)
    end

    def die_alpen_papier
      MailingList.find_by(internal_key: SacCas::MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY)
    end

    def die_alpen_digital
      MailingList.find_by(internal_key: SacCas::MAILING_LIST_DIE_ALPEN_DIGITAL_INTERNAL_KEY)
    end

    def fundraising
      MailingList.find_by(internal_key: SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY)
    end

    it "has newsletter mailing list" do
      expect(newsletter).not_to be_present
      MailingListSeeder.seed!
      expect(newsletter).to be_present
      expect(newsletter.subscribable_for).to eq("anyone")
      expect(newsletter.subscribable_mode).to eq("opt_in")
      expect(newsletter.filter_chain.to_hash).to be_blank
    end

    it "has customized subscribable_for translations" do
      label_nobody = subject.subscribable_for_label(:nobody)
      label_anyone = subject.subscribable_for_label(:anyone)
      label_configured = subject.subscribable_for_label(:configured)
      expect(label_nobody).to eq "Niemand"
      expect(label_anyone).to eq "Alle Personen des Schweizer Alpen-Clubs (u. A. alle Sektionen)"
      expect(label_configured).to eq "Nur konfigurierte Abonnenten (z.B. Sektionsmitglieder)"
    end

    it "newsletter mailing list subscription is empty" do
      MailingListSeeder.seed!
      expect(newsletter.subscriptions).to be_empty
    end

    it "has sac inside mailing list" do
      expect(sac_inside).not_to be_present
      MailingListSeeder.seed!
      expect(sac_inside).to be_present
      expect(sac_inside.subscribable_for).to eq("configured")
      expect(sac_inside.subscribable_mode).to eq("opt_in")
      expect(sac_inside.filter_chain.to_hash).to be_blank
    end

    it "has sac inside mailing list subscription" do
      MailingListSeeder.seed!
      expect(sac_inside.subscriptions).to contain_exactly(
        have_attributes(
          subscriber_id: Group.root_id,
          subscriber_type: Group.sti_name
        )
      )

      sub = sac_inside.subscriptions.first
      expect(sub.role_types).to match_array [
        Group::Geschaeftsstelle::Mitarbeiter,
        Group::Geschaeftsstelle::MitarbeiterLesend,
        Group::Geschaeftsstelle::Admin,
        Group::Geschaeftsstelle::Andere,
        Group::Geschaeftsleitung::Geschaeftsfuehrung,
        Group::Geschaeftsleitung::Ressortleitung,
        Group::Geschaeftsleitung::Andere,
        Group::Zentralvorstand::Praesidium,
        Group::Zentralvorstand::Mitglied,
        Group::Zentralvorstand::Andere,
        Group::Kommission::Praesidium,
        Group::Kommission::Mitglied,
        Group::Kommission::Andere,
        Group::SacCasPrivathuette::Huettenwart,
        Group::SacCasPrivathuette::Huettenchef,
        Group::SacCasPrivathuette::Andere,
        Group::SacCasClubhuette::Huettenwart,
        Group::SacCasClubhuette::Huettenchef,
        Group::SacCasClubhuette::Andere,
        Group::SektionsFunktionaere::Praesidium,
        Group::SektionsFunktionaere::Mitgliederverwaltung,
        Group::SektionsFunktionaere::Administration,
        Group::SektionsFunktionaere::AdministrationReadOnly,
        Group::SektionsFunktionaere::Finanzen,
        Group::SektionsFunktionaere::Redaktion,
        Group::SektionsFunktionaere::Huettenobmann,
        Group::SektionsFunktionaere::Andere,
        Group::SektionsFunktionaere::Umweltbeauftragter,
        Group::SektionsFunktionaere::Kulturbeauftragter,
        Group::SektionsVorstand::Praesidium,
        Group::SektionsVorstand::Mitglied,
        Group::SektionsVorstand::Andere,
        Group::SektionsTourenUndKurse::Tourenchef,
        Group::SektionsTourenUndKurse::TourenchefSommer,
        Group::SektionsTourenUndKurse::TourenchefWinter,
        Group::SektionsClubhuette::Huettenwart,
        Group::SektionsClubhuette::Huettenchef,
        Group::SektionsClubhuette::Andere,
        Group::Sektionshuette::Huettenwart,
        Group::Sektionshuette::Huettenchef,
        Group::Sektionshuette::Andere,
        Group::SektionsKommissionHuetten::Mitglied,
        Group::SektionsKommissionHuetten::Praesidium,
        Group::SektionsKommissionHuetten::Andere,
        Group::SektionsKommissionTouren::Mitglied,
        Group::SektionsKommissionTouren::Praesidium,
        Group::SektionsKommissionTouren::Andere,
        Group::SektionsKommissionUmweltUndKultur::Mitglied,
        Group::SektionsKommissionUmweltUndKultur::Praesidium,
        Group::SektionsKommissionUmweltUndKultur::Andere,
        Group::SektionsKommission::Mitglied,
        Group::SektionsKommission::Praesidium,
        Group::SektionsKommission::Andere
      ].map(&:sti_name)
    end

    it "has tourenleiter newsletter mailing list" do
      expect(tourenleiter).not_to be_present
      MailingListSeeder.seed!
      expect(tourenleiter).to be_present
      expect(tourenleiter.subscribable_for).to eq("configured")
      expect(tourenleiter.subscribable_mode).to eq("opt_in")
      expect(tourenleiter.filter_chain.to_hash).to be_blank
    end

    it "has tourenleiter newsletter mailing list subscription" do
      MailingListSeeder.seed!
      expect(tourenleiter.subscriptions).to contain_exactly(
        have_attributes(
          subscriber_id: Group.root_id,
          subscriber_type: Group.sti_name
        )
      )

      sub = tourenleiter.subscriptions.first
      expect(sub.role_types).to match_array [
        Group::SektionsTourenUndKurse::Tourenleiter,
        Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation
      ].map(&:sti_name)
    end

    it "has die alpen papier mailing list" do
      mailing_lists(:sac_magazine).destroy!
      expect(die_alpen_papier).not_to be_present
      MailingListSeeder.seed!
      expect(die_alpen_papier).to be_present
      expect(die_alpen_papier.subscribable_for).to eq("configured")
      expect(die_alpen_papier.subscribable_mode).to eq("opt_out")
      expect(die_alpen_papier.filter_chain.to_hash).to eq(
        "invoice_receiver" => {
          "stammsektion" => "true",
          "group_id" => Group.root_id,
          "deep" => true
        }
      )
    end

    it "has die alpen papier mailing list subscription" do
      MailingListSeeder.seed!
      expect(die_alpen_papier.subscriptions).to contain_exactly(
        have_attributes(
          subscriber_id: Group.root_id,
          subscriber_type: Group.sti_name
        )
      )

      sub = die_alpen_papier.subscriptions.first
      expect(sub.role_types).to match_array [
        Group::SektionsMitglieder::Mitglied
      ].map(&:sti_name)
    end

    it "has die alpen digital mailing list" do
      expect(die_alpen_digital).not_to be_present
      MailingListSeeder.seed!
      expect(die_alpen_digital).to be_present
      expect(die_alpen_digital.subscribable_for).to eq("configured")
      expect(die_alpen_digital.subscribable_mode).to eq("opt_in")
      expect(die_alpen_digital.filter_chain.to_hash).to be_blank
    end

    it "has die alpen digital mailing list subscription" do
      MailingListSeeder.seed!
      expect(die_alpen_digital.subscriptions).to contain_exactly(
        have_attributes(
          subscriber_id: Group.root_id,
          subscriber_type: Group.sti_name
        )
      )

      sub = die_alpen_digital.subscriptions.first
      expect(sub.role_types).to match_array [
        Group::SektionsMitglieder::Mitglied,
        Group::AboMagazin::Abonnent,
        Group::AboMagazin::Gratisabonnent
      ].map(&:sti_name)
    end

    it "has fundraising mailing list" do
      expect(fundraising).not_to be_present
      MailingListSeeder.seed!
      expect(fundraising).to be_present
      expect(fundraising.subscribable_for).to eq("nobody")
      expect(fundraising.subscribable_mode).to eq("opt_in")
      expect(fundraising.filter_chain.to_hash).to be_blank
    end

    it "fundraising mailing list subscription is empty" do
      MailingListSeeder.seed!
      expect(fundraising.subscriptions).to be_empty
    end

    it "updates Group.root#sac_newsletter_mailing_list_id" do
      expect { MailingListSeeder.seed! }
        .to change { Group.root.reload.sac_newsletter_mailing_list_id }
      expect(Group.root.sac_newsletter_mailing_list_id).to eq(newsletter.id)
    end

    it "updates Group.root#sac_fundraising_mailing_list_id" do
      expect { MailingListSeeder.seed! }
        .to change { Group.root.reload.sac_fundraising_mailing_list_id }
      expect(Group.root.sac_fundraising_mailing_list_id).to eq(fundraising.id)
    end
  end
end
