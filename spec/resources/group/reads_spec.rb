# frozen_string_literal: true

#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe GroupResource, :draper_with_helpers, type: :resource do
  include Rails.application.routes.url_helpers

  let(:person) { people(:admin) }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:ortsgruppe) { groups(:bluemlisalp_ortsgruppe_ausserberg) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }

  it "includes navision id" do
    params[:filter] = {id: {eq: bluemlisalp.id}}
    render
    expect(jsonapi_data[0].attributes["navision_id"]).to eq 1650
  end

  context "extra attributes" do
    context "mounted_attributes" do
      it "includes foundation year, section canton and language as extra attribute" do
        bluemlisalp.update!(created_at: 1.day.ago, foundation_year: 1900, section_canton: "BE",
          language: "FR")
        params[:filter] = {id: {eq: bluemlisalp.id}}
        params[:extra_fields] = {groups: "foundation_year,section_canton,language"}
        render
        expect(jsonapi_data[0].attributes["foundation_year"]).to eq "1900"
        expect(jsonapi_data[0].attributes["section_canton"]).to eq "BE"
        expect(jsonapi_data[0].attributes["language"]).to eq "FR"
      end

      it "returns blank values if group does not have underlying mounted attributes" do
        params[:filter] = {id: {eq: geschaeftsstelle.id}}
        params[:extra_fields] = {groups: "foundation_year,section_canton,language"}
        render
        expect(jsonapi_data[0].attributes["foundation_year"]).to be_blank
        expect(jsonapi_data[0].attributes["section_canton"]).to be_blank
        expect(jsonapi_data[0].attributes["language"]).to be_blank
      end
    end

    context "has_youth_organization" do
      before { params[:extra_fields] = {groups: "has_youth_organization"} }

      it 'is true for sektion with social account label "Homepage JO"' do
        bluemlisalp.social_accounts.create!(label: "Homepage JO", name: "https://www.bluemlisalp.ch")
        params[:filter] = {id: {eq: bluemlisalp.id}}
        render
        expect(jsonapi_data[0].attributes["has_youth_organization"]).to be true
      end

      it 'is false for sektion without social account label "Homepage JO"' do
        expect(bluemlisalp.social_accounts).to be_blank
        bluemlisalp.social_accounts.create!(label: "Homepage non-JO", name: "https://www.bluemlisalp.ch")
        params[:filter] = {id: {eq: bluemlisalp.id}}
        render
        expect(jsonapi_data[0].attributes["has_youth_organization"]).to be false
      end

      it 'is true for ortsgruppe with social account label "Homepage JO"' do
        ortsgruppe.social_accounts.create!(label: "Homepage JO", name: "https://www.bluemlisalp.ch")
        params[:filter] = {id: {eq: ortsgruppe.id}}
        render
        expect(jsonapi_data[0].attributes["has_youth_organization"]).to be true
      end

      it 'is false for ortsgruppe without social account label "Homepage JO"' do
        expect(ortsgruppe.social_accounts).to be_blank
        ortsgruppe.social_accounts.create!(label: "Homepage non-JO", name: "https://www.bluemlisalp.ch")
        params[:filter] = {id: {eq: ortsgruppe.id}}
        render
        expect(jsonapi_data[0].attributes["has_youth_organization"]).to be false
      end

      it 'is nil for other group types with social account label "Homepage JO"' do
        geschaeftsstelle.social_accounts.create!(label: "Homepage JO", name: "https://www.bluemlisalp.ch")
        params[:filter] = {id: {eq: geschaeftsstelle.id}}
        render
        expect(jsonapi_data[0].attributes["has_youth_organization"]).to be nil
      end
    end

    context "members_count" do
      before do
        mitglied_zusatzsektion = Fabricate(:person)
        Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
          group: groups(:matterhorn_mitglieder), person: mitglied_zusatzsektion)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.name.to_sym,
          group: groups(:bluemlisalp_mitglieder), person: mitglied_zusatzsektion)
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.name.to_sym,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: mitglied_zusatzsektion)

        params[:extra_fields] = {groups: "members_count"}
      end

      it "returns the count of Mitglied and MitgliedZusatzsektion on sektion" do
        mitglieder_counts = groups(:bluemlisalp_mitglieder).roles.group(:type).count
        expect(mitglieder_counts).to match(
          Group::SektionsMitglieder::Mitglied.name => 4,
          Group::SektionsMitglieder::MitgliedZusatzsektion.name => 1
        )
        params[:filter] = {id: {eq: bluemlisalp.id}}
        render
        expect(jsonapi_data[0].attributes["members_count"]).to eq mitglieder_counts.values.sum
      end

      it "returns the count of Mitglied and MitgliedZusatzsektion on ortsgruppe" do
        mitglieder_counts = groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder).roles.group(:type).count
        expect(mitglieder_counts).to match(
          Group::SektionsMitglieder::MitgliedZusatzsektion.name => 1
        )

        params[:filter] = {id: {eq: ortsgruppe.id}}
        render
        expect(jsonapi_data[0].attributes["members_count"]).to eq mitglieder_counts.values.sum
      end

      it "is nil for other group types" do
        params[:filter] = {id: {eq: geschaeftsstelle.id}}
        render
        expect(jsonapi_data[0].attributes["members_count"]).to be nil
      end
    end

    context "membership_admission_through_gs" do
      before { params[:extra_fields] = {groups: "membership_admission_through_gs"} }

      it "is true for sektion without SektionsNeuanmeldungenSektion" do
        Group::SektionsNeuanmeldungenSektion.where(parent_id: bluemlisalp.id).delete_all
        params[:filter] = {id: {eq: bluemlisalp.id}}
        render
        expect(jsonapi_data[0].attributes["membership_admission_through_gs"]).to be true
      end

      it "is false for sektion with SektionsNeuanmeldungenSektion" do
        params[:filter] = {id: {eq: bluemlisalp.id}}
        render
        expect(jsonapi_data[0].attributes["membership_admission_through_gs"]).to be false
      end

      it "is nil for other group types" do
        params[:filter] = {id: {eq: geschaeftsstelle.id}}
        render
        expect(jsonapi_data[0].attributes["membership_admission_through_gs"]).to be nil
      end
    end

    context "membership_self_registration_url" do
      let(:host) { Rails.configuration.action_mailer.default_url_options[:host] }

      before { params[:extra_fields] = {groups: "membership_self_registration_url"} }

      it "returns the self registration url for sektion" do
        params[:filter] = {id: {eq: bluemlisalp.id}}
        render
        expect(jsonapi_data[0].attributes["membership_self_registration_url"])
          .to eq bluemlisalp.sac_cas_self_registration_url(host)
      end

      it "returns the self registration url for ortsgruppe" do
        params[:filter] = {id: {eq: ortsgruppe.id}}
        render
        expect(jsonapi_data[0].attributes["membership_self_registration_url"])
          .to eq ortsgruppe.sac_cas_self_registration_url(host)
      end

      it "returns nil for other group types" do
        group = groups(:matterhorn_neuanmeldungen_sektion)
        expect(group).not_to respond_to(:sac_cas_self_registration_url)
        expect(group).to be_self_registration_active
        params[:filter] = {id: {eq: group.id}}
        render
        expect(jsonapi_data[0].attributes["membership_self_registration_url"]).to be nil
      end
    end
  end
end
