# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe OidcClaimSetup do
  let(:owner) { people(:admin) }
  let(:response) { :user_info }
  let(:token) { Doorkeeper::AccessToken.new(resource_owner_id: owner.id, scopes: scope) }
  let(:claim_keys) { claims.stringify_keys.keys }

  subject(:claims) { Doorkeeper::OpenidConnect::ClaimsBuilder.generate(token, response) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("RAILS_HOST_NAME", "localhost:3000").and_return("hitobito.example.com")
  end

  shared_examples "shared claims" do
    describe "phone" do
      it "is blank when no matching number exists" do
        expect(claim_keys).to include("phone")
      end

      it "returns first number with matching label" do
        owner.phone_numbers.create!(label: "Haupt-Telefon", number: "0791234560")
        owner.phone_numbers.create!(label: "Haupt-Telefon", number: "0791234561")
        expect(claims[:phone]).to eq "+41 79 123 45 60"
      end
    end
  end

  context "name" do
    let(:scope) { :name }
    let(:logo) { Rails.root.join("spec", "fixtures", "files", "images", "logo.png") }

    it "has fallback picture" do
      expect(claims[:picture_url]).to eq "http://test.host/packs-test/media/images/profile-c150952c7e2ec2cf298980d55b2bcde3.svg"
    end

    it "has redirect url to store image" do
      expect(owner.picture.attach(Rack::Test::UploadedFile.new(logo))).to eq true
      expect(claims[:picture_url]).to start_with "http://test.host/rails/active_storage/blobs/redirect"
    end

    it "membership_verify_url is nil" do
      expect(claims[:membership_verify_url]).to be_nil
    end

    context "mitglied" do
      let(:owner) { people(:mitglied) }

      before { allow_any_instance_of(People::Membership::VerificationQrCode).to receive(:membership_verify_token).and_return("aSuperSweetToken42") }

      it "membership_verify_url is present" do
        expect(claims[:membership_verify_url]).to eq "http://hitobito.example.com/verify_membership/aSuperSweetToken42"
      end
    end

    it_behaves_like "shared claims"
  end

  context "with_roles" do
    let(:scope) { :with_roles }

    it "includes layer_group_id and layer_group_name" do
      role = claims[:roles].first
      expect(role[:layer_group_id]).to eq groups(:root).id
      expect(role[:layer_group_name]).to eq "SAC/CAS"
    end

    describe "membership_years" do
      it "is blank when no matching number exists" do
        expect(claim_keys).to include("membership_years")
      end

      it "is blank when no matching number exists" do
        expect(claims[:membership_years]).to eq 0
      end
    end

    it_behaves_like "shared claims"
  end

  context "user_groups" do
    let(:role) { roles(:admin) }
    let(:scope) { :user_groups }
    let(:user_groups) { claims[:user_groups] }

    def create_role(key, role)
      group = key.is_a?(Group) ? key : groups(key)
      role_type = group.class.const_get(role)
      Fabricate(role_type.sti_name, group: group, person: owner)
    end

    it "includes SAC_employee key when matching role exists" do
      expect(user_groups).to include "SAC_employee"
      expect(user_groups).to include "Group::Geschaeftsstelle::Admin#384133472"
    end

    it "includes section_functionary key when matching role exists" do
      role = create_role(:bluemlisalp_funktionaere, "AdministrationReadOnly")
      expect(user_groups).to include "section_functionary"
      expect(user_groups).to include "Group::Geschaeftsstelle::Admin#384133472"
      expect(user_groups).to include format("%s#%d" % [role.type, role.group_id])
    end

    it "includes section_president key when matching role exists" do
      create_role(:bluemlisalp_funktionaere, "Praesidium")
      expect(user_groups).to include "section_president"
    end

    it "includes SAC_management key when matching role exists" do
      group = Fabricate(Group::Geschaeftsleitung.sti_name, parent: groups(:root))

      create_role(group, "Ressortleitung")
      expect(user_groups).to include "SAC_management"
    end

    it "includes SAC_member key when matching role exists" do
      create_role(:bluemlisalp_mitglieder, "Mitglied")
      expect(user_groups).to include "SAC_member"
      expect(user_groups).not_to include "SAC_member_additional"
    end

    it "includes SAC_member key when matching role exists" do
      create_role(:bluemlisalp_mitglieder, "Mitglied")
      create_role(:matterhorn_mitglieder, "MitgliedZusatzsektion")
      expect(user_groups).to include "SAC_member"
      expect(user_groups).to include "SAC_member_additional"
    end

    it "includes SAC_central_board_member key when matching role exists" do
      group = Fabricate(Group::Zentralvorstand.sti_name, parent: groups(:root))
      create_role(group, "Praesidium")
      expect(user_groups).to include "SAC_central_board_member"
    end

    it "includes SAC_central_board_member key when matching role exists" do
      group = Fabricate(Group::Kommission.sti_name, parent: groups(:root))
      create_role(group, "Praesidium")
      expect(user_groups).to include "SAC_commission_member"
    end

    it "includes SAC_tourenportal_subscriber key when matching role exists" do
      group = Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
      create_role(group, "Autor")
      expect(user_groups).to include "SAC_tourenportal_subscriber"
    end

    it "includes section_commission_member key when matching role exists" do
      kommissionen = Group::SektionsKommissionen.find_or_create_by(parent: groups(:bluemlisalp_funktionaere))
      group = Group::SektionsKommissionTouren.find_or_create_by(parent: kommissionen, name: "Foobar")
      create_role(group, "Mitglied")
      expect(user_groups).to include "section_commission_member"
    end

    it "includes huts_functionary key when matching role exists" do
      clubhuetten = Group::SektionsClubhuetten.find_or_create_by(parent: groups(:bluemlisalp_funktionaere))
      group = Fabricate(Group::SektionsClubhuette.sti_name, parent: clubhuetten)
      create_role(group, "Huettenwart")
      expect(user_groups).to include "huts_functionary"
    end

    it "includes huts_functionary key when huettenobmann role exists" do
      group = groups(:bluemlisalp_funktionaere)
      create_role(group, "Huettenobmann")
      expect(user_groups).to include "huts_functionary"
    end

    it "includes tourenportal_author key when matching role exists" do
      group = Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
      create_role(group, "Autor")
      expect(user_groups).to include "tourenportal_author"
    end

    it "includes tourenportal_community key when matching role exists" do
      group = Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
      create_role(group, "Community")
      expect(user_groups).to include "tourenportal_community"
    end

    it "includes tourenportal_community key when matching role exists" do
      group = Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
      create_role(group, "Community")
      expect(user_groups).to include "tourenportal_community"
    end

    it "includes tourenportal_administrator key when matching role exists" do
      group = Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
      create_role(group, "Admin")
      expect(user_groups).to include "tourenportal_administrator"
    end

    it "includes tourenportal_gratisabonnent key when matching role exists" do
      group = Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
      create_role(group, "Gratisabonnent")
      expect(user_groups).to include "tourenportal_gratisabonnent"
    end

    it "includes magazin_subscriber key when matching role exists" do
      group = Fabricate(Group::AboMagazin.sti_name, parent: groups(:abo_magazine))
      create_role(group, "Andere")
      expect(user_groups).to include "magazin_subscriber"
    end

    it "includes section_tour_functionary key when matching role exists" do
      create_role(:bluemlisalp_ortsgruppe_ausserberg_touren_und_kurse, "JoChef")
      expect(user_groups).to include "section_tour_functionary"
    end

    it "includes section_tour_functionary key when tourenleiter role exists" do
      create_role(:bluemlisalp_ortsgruppe_ausserberg_touren_und_kurse_sommer, "Tourenchef")
      expect(user_groups).to include "section_tour_functionary"
    end
  end
end
