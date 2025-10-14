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

        expect(dom).to have_selector("#membership-verify #details #member-name",
          text: "Edmund Hillary")
        expect(dom).to have_selector("#membership-verify #details #member-info div",
          text: "Mitglied: 600001")
        expect(dom).to have_selector("#membership-verify #details #member-info div",
          text: "Anzahl Mitgliedsjahre: #{Date.current.year - 2015}")

        expect(dom).to have_selector("#membership-verify #details .alert-success",
          text: "Mitgliedschaft gültig")
        expect(dom).to have_selector("#membership-verify #details .alert-success span.fa-check")

        expect(dom).to have_selector("#membership-verify #details #sections strong",
          text: "Mitglied (Stammsektion) (Einzel)")
        expect(dom).to have_selector("#membership-verify #details #sections strong",
          text: "SAC Blüemlisalp")

        expect(dom).to have_selector("#membership-verify #details #sections div",
          text: "Mitglied (Zusatzsektion) (Einzel)")
        expect(dom).to have_selector("#membership-verify #details #sections div",
          text: "SAC Matterhorn")

        expect(dom).not_to have_selector("#membership-verify #details div",
          text: "Aktive/r Tourenleiter/in")
      end

      it "confirms active tour guide" do
        person.qualifications.create!(
          qualification_kind: qualification_kinds(:ski_leader),
          start_at: 1.month.ago
        )
        person.roles.create!(
          type: Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
          group: groups(:matterhorn_touren_und_kurse)
        )

        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify #details div",
          text: "Aktive/r Tourenleiter/in")
      end

      it "confirms invalid membership" do
        person.roles.destroy_all

        get :show, params: {verify_token: verify_token}

        expect(dom).to have_selector("#membership-verify #details .alert-danger",
          text: "Mitgliedschaft ungültig")
        # rubocop:todo Layout/LineLength
        expect(dom).to have_selector("#membership-verify #details .alert-danger span.fa-times-circle")
        # rubocop:enable Layout/LineLength

        expect(dom).to_not have_selector("#membership-verify #details #sections strong",
          text: "Mitglied (Stammsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections strong",
          text: "SAC Blüemlisalp")

        expect(dom).to_not have_selector("#membership-verify #details #sections div",
          text: "Mitglied (Zusatzsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections div",
          text: "SAC Matterhorn")
      end

      it "returns invalid code message for non existent verify token" do
        get :show, params: {verify_token: "gits-nid"}

        expect(dom).to_not have_selector("#membership-verify #details #member-name",
          text: "Edmund Hillary")
        expect(dom).to_not have_selector("#membership-verify #details #member-info div",
          text: "Mitglied: 600001")
        expect(dom).to_not have_selector("#membership-verify #details #member-info div",
          text: "Anzahl Mitgliedsjahre: 1")

        expect(dom).to_not have_selector("#membership-verify #details .alert-success",
          text: "Mitgliedschaft gültig")
        expect(dom).to_not have_selector("#membership-verify #details .alert-success span.fa-check")

        expect(dom).to_not have_selector("#membership-verify #details #sections strong",
          text: "Mitglied (Stammsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections strong",
          text: "SAC Blüemlisalp")

        expect(dom).to_not have_selector("#membership-verify #details #sections div",
          text: "Mitglied (Zusatzsektion) (Einzel)")
        expect(dom).to_not have_selector("#membership-verify #details #sections div",
          text: "SAC Matterhorn")

        expect(dom).to have_selector("#membership-verify #details .alert-danger",
          text: "Ungültiger Verifikationscode")
        # rubocop:todo Layout/LineLength
        expect(dom).to have_selector("#membership-verify #details .alert-danger span.fa-times-circle")
        # rubocop:enable Layout/LineLength
      end

      it "renders the website logo in correct language" do
        original_view_context = controller.view_context
        view_context = controller.view_context
        # In order to stub a method on the view_context we need to make sure our copy is used.
        allow(controller).to receive(:view_context).and_return(view_context)

        logos = Settings.application.logo.multilanguage_image.to_h
        logos[:default] = Settings.application.logo.image.to_s

        # Stub wagon_image_pack_tag to return logo or use original implementation for other images
        allow(view_context).to receive(:wagon_image_pack_tag) do |name, **options|
          if logos.value?(name)
            view_context.content_tag(:img, nil, src: name, **options)
          else
            original_view_context.wagon_image_pack_tag(name, **options)
          end
        end

        # Go through locales, render page and check dom for logo
        %i[fr it de].each do |locale| # de locale at the end to avoid flaky specs
          I18n.with_locale(locale) do
            get :show, params: {verify_token: "gits-nid", locale: locale}
            dom = Capybara::Node::Simple.new(response.body)

            expect(dom).to have_selector("#logo")
            logo_img_src = dom.find("#logo img")[:src]
            expect(logo_img_src).to eq logos[locale]
            logo_img_alt = dom.find("#logo img")[:alt]
            expect(logo_img_alt).to eq "SAC/CAS-Portal"
          end
        end
      end

      it "renders the sponsor logo in the locale language" do
        original_view_context = controller.view_context
        view_context = controller.view_context
        # In order to stub a method on the view_context we need to make sure our copy is used.
        allow(controller).to receive(:view_context).and_return(view_context)

        logos = %i[de fr it].map { |locale|
          [locale, "membership_verify_partner_ad_#{locale.downcase}.jpg"]
        }.to_h

        # Stub wagon_image_pack_tag to return logo or use original implementation for other images
        allow(view_context).to receive(:wagon_image_pack_tag) do |name, **options|
          if logos.value?(name)
            view_context.content_tag(:img, nil, src: name, **options)
          else
            original_view_context.wagon_image_pack_tag(name, **options)
          end
        end

        sponsor_links = {
          de: "https://www.sac-cas.ch/de/der-sac/unsere-partner/",
          fr: "https://www.sac-cas.ch/fr/le-cas/nos-partenaires/",
          it: "https://www.sac-cas.ch/it/il-cas/i-nostri-partner/"
        }

        %i[fr it de].each do |locale| # de locale at the end to avoid flaky specs
          I18n.with_locale(locale) do
            get :show, params: {verify_token: "gits-nid", locale: locale}
            dom = Capybara::Node::Simple.new(response.body)

            logo_img_src = dom.find("#sponsors img")[:src]
            logo_img_url = dom.find("#sponsors a")[:href]
            expect(logo_img_src).to eq logos[locale]
            expect(logo_img_url).to eq sponsor_links[locale]
          end
        end
      end
    end
  end
end
