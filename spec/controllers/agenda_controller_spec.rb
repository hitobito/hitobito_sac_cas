# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe AgendaController do
  render_views

  let(:group) { groups(:bluemlisalp) }
  let(:tour) { events(:section_tour) }
  let(:course) { events(:top_course) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    tour.update!(globally_visible: true)
    tour.update_column(:state, :published)
    tour.dates.update_all(start_at: 1.month.from_now)

    course.update!(globally_visible: true)
    course.dates.update_all(start_at: 1.month.from_now)
    allow(course).to receive(:assert_type_is_allowed_for_groups).and_return(true)
    course.update(groups: [group])
  end

  describe "GET #index" do
    it "renders info alert when no group_id given" do
      get :index

      expect(response).to render_template(layout: "agenda")
      expect(dom).to have_content("Bitte geben Sie eine Sektion an, deren Anlässe angezeigt werden sollen")
    end

    it "renders with agenda a layout" do
      get :index, params: {group_id: group.id}
      expect(response).to render_template(layout: "agenda")
    end

    it "renders without a layout for turbo frame requests" do
      request.headers["Turbo-Frame"] = "agenda_events_list"
      get :index, params: {group_id: group.id}

      expect(response).to render_template(layout: false)
    end

    it "includes globally visible tours for the specific group" do
      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).to include(tour)
    end

    it "includes all event types" do
      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).to include(course)
    end

    it "includes events that match the type filter" do
      get :index, params: {group_id: group.id, filters: {type: {types: ["Event::Tour"]}}}
      expect(controller.send(:events)).not_to include(course)
    end

    it "excludes events from other groups" do
      tour.update!(groups: [groups(:matterhorn)])
      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours older than 12 months per default" do
      tour.dates.update_all(start_at: 13.months.ago)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "includes tours older than 12 months with since filter" do
      tour.dates.update_all(start_at: 13.months.ago)

      get :index, params: {group_id: group.id, filters: {date_range: {since: ["01.01.2020"]}}}
      expect(controller.send(:events)).to include(tour)
    end

    it "includes future tours per default" do
      tour.dates.update_all(start_at: 13.months.from_now)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).to include(tour)
    end

    it "excludes tours that are not globally_visible" do
      tour.update!(globally_visible: false)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours that are in state draft" do
      tour.update_column(:state, :draft)

      get :index, params: {group_id: group.id}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours after until filter" do
      tour.dates.update_all(start_at: 1.month.from_now)

      get :index, params: {group_id: group.id, filters: {date_range: {until: "01.01.2020"}}}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "expcludes tours with applciation window closed with application window open filter" do
      tour.update!(application_opening_at: 2.months.ago, application_closing_at: 1.month.ago)

      get :index, params: {group_id: group.id, filters: {application_open: {value: 1}}}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes full tours with places available filter" do
      tour.update!(maximum_participants: 10, participant_count: 10)

      get :index, params: {group_id: group.id, filters: {places_available: {value: 1}}}
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours not having target group from filter" do
      get :index, params: {
        group_id: group.id,
        filters: {tour_essentials: {target_group_id: event_target_groups(:senioren).id}}
      }
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours not having activity from filter" do
      get :index, params: {
        group_id: group.id,
        filters: {tour_essentials: {activity_id: event_activities(:hochtour).id}}
      }
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours not having technical requirement from filter" do
      get :index, params: {
        group_id: group.id,
        filters: {tour_essentials: {technical_requirement_id: event_technical_requirements(:klettern).id}}
      }
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours not having fitness requirement from filter" do
      get :index, params: {
        group_id: group.id,
        filters: {tour_essentials: {fitness_requirement_id: event_fitness_requirements(:e).id}}
      }
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours not having trait from filter" do
      get :index, params: {
        group_id: group.id,
        filters: {tour_essentials: {trait_id: event_traits(:training).id}}
      }
      expect(controller.send(:events)).not_to include(tour)
    end

    it "excludes tours not having leader from filter" do
      get :index, params: {
        group_id: group.id,
        filters: {leader: {ids: people(:familienmitglied2).id}}
      }
      expect(controller.send(:events)).not_to include(tour)
    end

    it "loads the leaders of every rendered event in one go, avoiding an N+1" do
      add_leader(tour, people(:admin), Event::Role::Leader)
      add_leader(course, people(:familienmitglied2), Event::Course::Role::Leader)

      expect(AgendaLeaders).to receive(:new).once.and_call_original

      get :index, params: {group_id: group.id}

      expect(dom).to have_css(".agenda-tour-card-meta-row", text: "Anna Admin")
      expect(dom).to have_css(".agenda-tour-card-meta-row", text: "Frieda Norgay")
    end

    context "with remembered filters" do
      it "restores filters from a previous request when returning" do
        get :index, params: {group_id: group.id, filters: {type: {types: ["Event::Course"]}}}

        get :index, params: {group_id: group.id, returning: true}

        expect(controller.send(:events)).to include(course)
      end

      it "carries remembered filters over to a different group" do
        other_group = groups(:matterhorn)
        course.update!(groups: [group, other_group])

        get :index, params: {group_id: group.id, filters: {type: {types: ["Event::Course"]}}}

        get :index, params: {group_id: other_group.id, returning: true}

        expect(controller.send(:events)).to include(course)
      end
    end
  end

  describe "GET #show" do
    it "renders the tour" do
      get :show, params: {group_id: group.id, event_id: tour.id}

      expect(response).to render_template(layout: "agenda")
      expect(dom).to have_content(tour.name)
    end

    it "renders a course, which has none of Event::Tour's own attributes/associations" do
      get :show, params: {group_id: group.id, event_id: course.id}

      expect(response).to render_template(layout: "agenda")
      expect(dom).to have_content(course.name)
    end

    describe "the contact block" do
      subject(:profile) do
        get :show, params: {group_id: group.id, event_id: tour.id}
        dom.find(".agenda-contact-profile")
      end

      let(:contact) { people(:admin) }

      before do
        contact.phone_numbers.create!(label: "landline", number: "+41 79 123 45 67", public: true)
        contact.social_accounts.create!(label: "Webseite", name: "sac-cas.example.com",
          public: true)
      end

      it "renders every contact attribute the event publishes" do
        expect(profile).to have_content("Anna Admin")
        expect(profile).to have_content("Ophovenerstrasse 79a")
        expect(profile).to have_content("2843 Neu Carlscheid")
        expect(profile).to have_link("+41 79 123 45 67", href: "tel:+41791234567")
        expect(profile).to have_link("support@hitobito.example.com",
          href: "mailto:support@hitobito.example.com")
        expect(profile).to have_content("sac-cas.example.com")
      end

      it "renders the contact picture" do
        contact.picture.attach(
          io: Rails.root.join("spec", "fixtures", "person", "test_picture.jpg").open,
          filename: "test_picture.jpg"
        )
        tour.update!(visible_contact_attributes: Event::ALLOWED_VISIBLE_CONTACT_ATTRIBUTES)

        expect(profile).to have_css("img.agenda-contact-avatar")
        expect(profile).not_to have_css(".agenda-contact-avatar-initials", text: "AA")
      end

      it "renders initials when the picture is not published" do
        contact.picture.attach(
          io: Rails.root.join("spec", "fixtures", "person", "test_picture.jpg").open,
          filename: "test_picture.jpg"
        )

        expect(profile).to have_css(".agenda-contact-avatar-initials", text: "AA")
      end

      it "renders only the attributes listed in visible_contact_attributes" do
        tour.update!(visible_contact_attributes: %w[name email])

        expect(profile).to have_content("Anna Admin")
        expect(profile).to have_link("support@hitobito.example.com")
        expect(profile).not_to have_content("Ophovenerstrasse")
        expect(profile).not_to have_link("+41 79 123 45 67")
        expect(profile).not_to have_content("sac-cas.example.com")
        expect(profile).to have_css(".agenda-contact-avatar-initials")
      end

      it "renders no contact block when the event publishes nothing" do
        tour.update!(visible_contact_attributes: [])

        get :show, params: {group_id: group.id, event_id: tour.id}

        expect(dom).not_to have_css(".agenda-contact-profile")
      end

      it "renders no contact block for an event without a contact" do
        # A tour insists on a contact, so this has to go around the validation
        # - the agenda still renders event types that allow none.
        tour.update_column(:contact_id, nil)

        get :show, params: {group_id: group.id, event_id: tour.id}

        expect(dom).not_to have_css(".agenda-contact-profile")
      end
    end
  end

  # The tour card and the detail page render the same event facts with
  # deliberately different markup, so these examples pin what each one puts on
  # the page - the only safety net for the logic shared between the two.
  describe "rendered event facts" do
    around { |example| travel_to(Time.zone.local(2026, 1, 15)) { example.run } }

    before do
      # Before the participant_count below: activating a role recounts it.
      add_leader(tour, people(:admin), Event::Role::Leader)
      add_leader(tour, people(:mitglied), Event::Role::AssistantLeader)

      tour.update!(
        display_booking_info: true,
        maximum_participants: 30,
        participant_count: 3,
        application_opening_at: Time.zone.local(2025, 12, 1),
        application_closing_at: Time.zone.local(2026, 2, 1)
      )
      tour.dates.update_all(start_at: Time.zone.local(2026, 3, 2), finish_at: nil)
    end

    describe "tour card" do
      subject(:card) do
        get :index, params: {group_id: group.id, filters: {type: {types: ["Event::Tour"]}}}
        dom.find("article.agenda-tour-card")
      end

      it "renders the activity, target group and trait badges" do
        expect(card).to have_css(".agenda-activity-badge", text: "WANDERWEG")
        expect(card.all(".agenda-badge-outline").map(&:text))
          .to eq ["Kinder (KiBe)", "Familien (FaBe)", "Anreise mit ÖV", "Exkursion"]
      end

      it "renders the status badge" do
        expect(card).to have_css(".agenda-status-badge.agenda-status-application_open",
          text: "Anmeldung offen")
      end

      it "renders one meta row per available fact" do
        expect(card).to have_css(".agenda-tour-card-meta-row", count: 7)
      end

      it "renders dates, duration, requirements and elevation" do
        expect(card).to have_css(".agenda-tour-card-value", text: "Mo 02.03.2026")
        expect(card).to have_text "1 Tag"
        expect(card).to have_text "Kondition"
        expect(card).to have_css(".agenda-tour-card-value.fw-bold", text: "B")
        expect(card).to have_css(".agenda-requirement-badge", text: "T3, T4")
        expect(card).to have_text "↑ 2872 m / ↓ 911 m"
      end

      it "renders the participant count with its suffix and the leaders" do
        expect(card.find(".agenda-tour-card-value", text: "Teilnehmende").text.squish)
          .to eq "3/30 Teilnehmende"
        expect(card.find(".agenda-tour-card-value", text: "Admin").text.squish)
          .to eq "Anna Admin Edmund Hillary"
        expect(card).not_to have_content("Kontaktperson")
      end

      it "links to the application and to the detail page" do
        expect(card).to have_link("Anmelden",
          href: contact_data_group_event_participations_path(group, tour))
        expect(card).to have_link("Details", href: agenda_show_path(group, tour))
      end

      it "renders the application deadline" do
        expect(card.find("p.agenda-fact-label").text.squish).to eq "Anmeldeschluss: 01.02.2026"
      end

      context "when the application has not opened yet" do
        before do
          tour.update!(application_opening_at: Time.zone.local(2026, 6, 1),
            application_closing_at: Time.zone.local(2026, 7, 1))
        end

        it "renders the opening date and no application link" do
          expect(card.find("p.agenda-fact-label").text.squish).to eq "Anmeldebeginn: 01.06.2026"
          expect(card).not_to have_link("Anmelden")
        end
      end

      context "when the tour is full" do
        before { tour.update!(participant_count: 30) }

        it "offers the waiting list" do
          expect(card).to have_link("Warteliste")
          expect(card).to have_css(".agenda-status-badge.agenda-status-application_waiting")
        end
      end

      context "without booking info" do
        before { tour.update!(display_booking_info: false) }

        it "renders the participant limit instead of the count" do
          expect(card).to have_text "Max. 30 Teilnehmende"
          expect(card).not_to have_text "3/30"
        end

        it "renders no participant info without a limit, same as the detail page" do
          tour.update!(maximum_participants: 0)

          expect(card).not_to have_text "Teilnehmende"
        end
      end
    end

    describe "detail page" do
      subject(:detail) do
        get :show, params: {group_id: group.id, event_id: tour.id}
        dom.find(".agenda-tour-detail-body")
      end

      let(:header) { dom.find(".agenda-tour-detail-header") }

      it "hands the accent colour to the stylesheet once, on the outer element" do
        detail # renders the page

        expect(dom.find(".agenda-tour-detail")[:style]).to eq "--tour-color: #237100"
      end

      it "renders the activity and the requirements in the header" do
        detail # renders the page

        expect(header).to have_css(".agenda-tour-detail-type", text: "WANDERWEG")
        expect(header.all(".agenda-tour-detail-header-badge").map(&:text)).to eq ["\nT3\n", "\nT4\n"]
      end

      it "renders the status badge before the target group and trait badges" do
        expect(detail).to have_css(".agenda-status-badge.agenda-status-application_open",
          text: "Anmeldung offen")
        expect(detail.all(".agenda-badge-outline").map(&:text))
          .to eq ["Kinder (KiBe)", "Familien (FaBe)", "Anreise mit ÖV", "Exkursion"]
      end

      it "renders one labelled fact per available detail" do
        expect(facts(detail)).to eq(
          "Datum" => "Mo 02.03.2026",
          "Dauer" => "1 Tag / 12:30 h",
          "Gipfel" => "Bettmerhorn",
          "Höhenmeter" => "↑ 2872 m / ↓ 911 m",
          "Technische Anforderungen" => "T3 T4",
          "Konditionelle Anforderung" => "B - wenig anstrengend",
          "Teilnehmende" => "3/30",
          "Tourenleitung" => "Anna Admin Edmund Hillary",
          "Kosten" => "Sektionsmitglieder CHF 50 SAC-Mitglieder CHF 60 Nicht-Mitglieder CHF 80"
        )
      end

      it "links the summit to the tourenportal" do
        expect(detail).to have_link("Bettmerhorn", href: tour.tourenportal_link)
      end

      it "renders one text section per filled attribute" do
        expect(sections(detail)).to eq(
          "Beschreibung" => "Winterzauber im wunderschönen Kiental",
          "Zusatzinfo" => "Wichtige Infos, welche gelesen werden sollten",
          "Alternativroute" => "Ich kenne mich aus, vertrau mir",
          "Kosten" => "Sektionsmitglieder CHF 50 SAC-Mitglieder CHF 60 Nicht-Mitglieder CHF 80"
        )
      end

      it "renders the deadline and the application link" do
        expect(detail.find(".agenda-tour-detail-deadline").text.squish)
          .to eq "Anmeldeschluss: 01.02.2026"
        expect(detail).to have_link("Anmelden",
          href: contact_data_group_event_participations_path(group, tour))
      end

      context "for an event that is not a tour" do
        subject(:detail) do
          get :show, params: {group_id: group.id, event_id: course.id}
          dom.find(".agenda-tour-detail-body")
        end

        before { course.dates.update_all(start_at: Time.zone.local(2026, 4, 1), finish_at: nil) }

        it "renders only the facts that are not tour-specific" do
          expect(facts(detail).keys).to eq ["Datum", "Dauer", "Teilnehmende"]
          expect(facts(detail)["Datum"]).to include "Mi 01.04.2026"
          expect(detail).not_to have_css(".agenda-badge-outline")
          expect(detail).not_to have_css(".agenda-requirement-badge")
        end

        it "sets no accent colour, leaving the stylesheet's neutral fallback" do
          detail # renders the page

          expect(dom.find(".agenda-tour-detail")[:style]).to be_blank
          expect(header).not_to have_css(".agenda-tour-detail-type")
        end
      end
    end
  end

  def add_leader(event, person, role_type)
    participation = Fabricate(:event_participation, event: event, participant: person)
    role_type.create!(participation: participation)
  end

  # label => value of every fact in the detail page's fact grid
  def facts(node)
    node.all(".agenda-fact").to_h do |fact|
      [fact.find(".agenda-fact-label").text, fact.find(".agenda-fact-value").text.squish]
    end
  end

  # title => text of every text section in the detail page's lower half
  def sections(node)
    node.all(".agenda-tour-detail-columns :not(.agenda-tour-detail-contact) .agenda-section-title").to_h do |title|
      [title.text, title.find(:xpath, "following-sibling::*[1]").text.squish]
    end
  end
end
