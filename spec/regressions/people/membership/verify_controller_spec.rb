# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Membership::VerifyController, type: :controller do
  render_views

  let(:person) { people(:mitglied) }
  let(:verify_token) { person.membership_verify_token }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  describe "GET #show" do
    context "with feature enabled" do
      before { allow(::People::Membership::Verifier).to receive(:enabled?).and_return(true) }

      it "confirms active membership" do
        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify #details #member-name", text: "Edmund Hillary")
        expect(dom).to have_selector("#membership-verify #details #member-info div", text: "Mitglied: 600001")
        expect(dom).to have_selector("#membership-verify #details #member-info div", text: "Anzahl Mitgliedsjahre: 1")

        expect(dom).to have_selector("#membership-verify #details .alert-success", text: "Mitgliedschaft gültig")
        expect(dom).to have_selector("#membership-verify #details .alert-success span.fa-check")

        expect(dom).to have_selector("#membership-verify #details #sections strong", text: "Mitglied (Stammsektion) (Einzel)")
        expect(dom).to have_selector("#membership-verify #details #sections strong", text: "SAC Blüemlisalp")

        expect(dom).to have_selector("#membership-verify #details #sections div", text: "Mitglied (Zusatzsektion) (Einzel)")
        expect(dom).to have_selector("#membership-verify #details #sections div", text: "SAC Matterhorn")

        expect(dom).not_to have_selector("#membership-verify #details div", text: "Aktive/r Tourenleiter/in")
      end

      it "confirms active tour guide" do
        person.qualifications.create!(
          qualification_kind: qualification_kinds(:ski_leader),
          start_at: 1.month.ago
        )
        person.roles.create!(
          type: Group::SektionsTourenkommission::Tourenleiter.sti_name,
          group: groups(:matterhorn_tourenkommission)
        )

        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify #details div", text: "Aktive/r Tourenleiter/in")
      end

      it "confirms invalid membership" do
        person.roles.destroy_all

        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify #details .alert-danger", text: "Mitgliedschaft ungültig")
        expect(dom).to have_selector("#membership-verify #details .alert-danger span.fa-times-circle")

        expect(dom).to_not have_selector("#membership-verify #details #sections strong", text: "Mitglied (Stammsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections strong", text: "SAC Blüemlisalp")

        expect(dom).to_not have_selector("#membership-verify #details #sections div", text: "Mitglied (Zusatzsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections div", text: "SAC Matterhorn")
      end

      it "returns invalid code message for non existent verify token" do
        get :show, params: {verify_token: "gits-nid"}

        expect(dom).to_not have_selector("#membership-verify #details #member-name", text: "Edmund Hillary")
        expect(dom).to_not have_selector("#membership-verify #details #member-info div", text: "Mitglied: 600001")
        expect(dom).to_not have_selector("#membership-verify #details #member-info div", text: "Anzahl Mitgliedsjahre: 1")

        expect(dom).to_not have_selector("#membership-verify #details .alert-success", text: "Mitgliedschaft gültig")
        expect(dom).to_not have_selector("#membership-verify #details .alert-success span.fa-check")

        expect(dom).to_not have_selector("#membership-verify #details #sections strong", text: "Mitglied (Stammsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections strong", text: "SAC Blüemlisalp")

        expect(dom).to_not have_selector("#membership-verify #details #sections div", text: "Mitglied (Zusatzsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections div", text: "SAC Matterhorn")

        expect(dom).to have_selector("#membership-verify #details .alert-danger", text: "Ungültiger Verifikationscode")
        expect(dom).to have_selector("#membership-verify #details .alert-danger span.fa-times-circle")
      end
    end
  end
end
