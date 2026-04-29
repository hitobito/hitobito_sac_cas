# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Group::Ortsgruppe do
  context "validations" do
    context "section_canton" do
      def ortsgruppe(canton)
        Group::Ortsgruppe.new(section_canton: canton).tap(&:validate)
      end

      it "allows valid canton" do
        expect(ortsgruppe("BE").errors[:section_canton]).to be_empty
      end

      it "allows blank canton" do
        expect(ortsgruppe(nil).errors[:section_canton]).to be_empty
      end

      it "does not allow invalid canton" do
        expect(ortsgruppe("Bern").errors[:section_canton]).to eq ["ist kein gültiger Wert"]
        expect(ortsgruppe("").errors[:section_canton]).to eq ["ist kein gültiger Wert"]
      end
    end
  end

  context "sac self registration url" do
    let(:ortsgruppe) { groups(:bluemlisalp_ortsgruppe_ausserberg) }
    let(:neuanmeldungen_nv) { groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv) }
    let(:url) { ortsgruppe.sac_cas_self_registration_url("db.sac-cas.ch") }

    it "gets url from neuanmeldungen nv group" do
      expect(url).to eq("http://db.sac-cas.ch/de/groups/#{neuanmeldungen_nv.id}/self_registration")
    end
  end

  context "tour notification mailing lists" do
    let(:ortsgruppe) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

    context "if already present" do
      before do
        expect(ortsgruppe.tours_enabled).to eq(false)

        ortsgruppe.send(:create_tour_notification_mailing_lists)
        expect(ortsgruppe.mailing_lists.size).to eq(3)
        expect(ortsgruppe.mailing_lists.pluck(:internal_key)).to include(
          ::SacCas::MAILING_LIST_REGULAR_TOUR_INTERNAL_KEY,
          ::SacCas::MAILING_LIST_SUBITO_TOUR_INTERNAL_KEY
        )
      end

      it "do not get created when enabling tours" do
        expect do
          ortsgruppe.update!(tours_enabled: true)
        end.to_not change { MailingList.count }

        expect(ortsgruppe.reload.tours_enabled).to eq(true)
      end

      it "do not get deleted when disabling tours" do
        ortsgruppe.update!(tours_enabled: true)
        expect do
          ortsgruppe.update!(tours_enabled: false)
        end.to_not change { MailingList.count }
      end
    end

    context "if not present" do
      before do
        expect(ortsgruppe.mailing_lists.size).to eq(1)
        expect(ortsgruppe.mailing_lists.pluck(:internal_key)).to_not include(
          ::SacCas::MAILING_LIST_REGULAR_TOUR_INTERNAL_KEY,
          ::SacCas::MAILING_LIST_SUBITO_TOUR_INTERNAL_KEY
        )
      end

      it "get created when enabling tours" do
        expect do
          ortsgruppe.update!(tours_enabled: true)
        end.to change { MailingList.count }.by(2)

        expect(ortsgruppe.mailing_lists.size).to eq(3)
        expect(ortsgruppe.mailing_lists.pluck(:internal_key)).to include(
          ::SacCas::MAILING_LIST_REGULAR_TOUR_INTERNAL_KEY,
          ::SacCas::MAILING_LIST_SUBITO_TOUR_INTERNAL_KEY
        )
      end
    end
  end
end
