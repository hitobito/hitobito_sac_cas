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
      expect(url).to eq("http://db.sac-cas.ch/groups/#{neuanmeldungen_nv.id}/self_registration")
    end
  end
end
