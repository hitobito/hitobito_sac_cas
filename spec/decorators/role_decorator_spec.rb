# frozen_string_literal: true

#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe RoleDecorator, :draper_with_helpers do
  let(:today) { Time.zone.today }
  let(:decorator) { described_class.new(role) }

  describe "#for_aside" do
    let(:decorated_name) { decorator.for_aside }

    context "mitglied role" do
      let(:role) { roles(:mitglied) }

      it "includes beitragskategorie" do
        formatted_name = "<strong>Mitglied (Stammsektion) (Einzel)</strong>&nbsp;(bis 31.12.#{today.year})"

        expect(decorated_name).to eq(formatted_name)
      end

      it "includes label and beitragskategorie" do
        role.label = "test"
        formatted_name = "<strong>Mitglied (Stammsektion) (Einzel)</strong>&nbsp;(test)&nbsp;(bis 31.12.#{today.year})"

        expect(decorated_name).to eq(formatted_name)
      end
    end

    context "neuanmeldung role" do
      let(:neuanmeldungen) { groups(:bluemlisalp_neuanmeldungen_nv) }
      let(:role) do
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
          delete_on: today.end_of_year,
          group: neuanmeldungen)
      end

      it "includes beitragskategorie" do
        formatted_name = "<strong>Neuanmeldung (Stammsektion) (Einzel)</strong>&nbsp;(bis 31.12.#{today.year})"

        expect(decorated_name).to eq(formatted_name)
      end

      it "includes label and beitragskategorie" do
        role.label = "test"
        formatted_name = "<strong>Neuanmeldung (Stammsektion) (Einzel)</strong>&nbsp;(test)&nbsp;(bis 31.12.#{today.year})"

        expect(decorated_name).to eq(formatted_name)
      end
    end

    context "non mitglied role" do
      let(:role) { roles(:admin) }

      it "never includes beitragskategorie" do
      end
    end
  end
end
