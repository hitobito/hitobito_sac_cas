# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Group::Sektion do
  context "validations" do
    context "section_canton" do
      def sektion(canton)
        Group::Sektion.new(section_canton: canton).tap(&:validate)
      end

      it "allows valid canton" do
        expect(sektion("BE").errors[:section_canton]).to be_empty
      end

      it "allows blank canton" do
        expect(sektion(nil).errors[:section_canton]).to be_empty
      end

      it "does not allow invalid canton" do
        expect(sektion("Bern").errors[:section_canton]).to eq ["ist kein gültiger Wert"]
        expect(sektion("").errors[:section_canton]).to eq ["ist kein gültiger Wert"]
      end
    end
  end

  context "sac self registration url" do
    let(:sektion) { groups(:bluemlisalp) }
    let(:neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }
    let(:neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:url) { sektion.sac_cas_self_registration_url("db.sac-cas.ch") }

    it "gets url from neuanmeldungen sektion group" do
      expect(url).to eq("http://db.sac-cas.ch/groups/#{neuanmeldungen_sektion.id}/self_registration")
    end

    it "gets url from neuanmeldungen nv group" do
      neuanmeldungen_sektion.really_destroy!

      expect(url).to eq("http://db.sac-cas.ch/groups/#{neuanmeldungen_nv.id}/self_registration")
    end

    it "no url if no neuanmeldungen group" do
      neuanmeldungen_sektion.really_destroy!
      neuanmeldungen_nv.really_destroy!

      expect(url).to be_nil
    end
  end
end
