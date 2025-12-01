# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Pdf::Participations::ParticipantList do
  include PdfHelpers

  let(:event) { events(:top_course) }
  let(:group) { event.groups.first }
  let(:list_kind) { "for_participants" }

  let(:pdf) { subject.render }
  let(:text_analyzer) { PDF::Inspector::Text.analyze(pdf) }

  subject { described_class.new(event, list_kind, "test.host") }

  before do
    event.update!(location: "Berghotel Schwarenbach\n3752 Kandersteg")

    # The sorting has to happen like this because rails and postgres treat "Umlaute"
    # differently
    @leaders = Person.where(id: [
      Fabricate(Event::Course::Role::Leader.name.to_sym,
        participation: Fabricate(:event_participation, event: event)),
      Fabricate(Event::Course::Role::Leader.name.to_sym,
        participation: Fabricate(:event_participation, event: event))
    ].map { |role| role.participation.person.id }).order(:last_name).to_a

    @aspirant = Fabricate(Event::Course::Role::AssistantLeaderAspirant.name.to_sym,
      participation: Fabricate(:event_participation, event: event)).participation.person
    Fabricate(:phone_number, contactable: people(:familienmitglied),
      label: :mobile, number: "+41 77 360 75 63")
    Fabricate(:phone_number, contactable: people(:mitglied),
      label: :landline, number: "+41 77 484 21 96")
  end

  it "renders text" do
    text = text_analyzer.show_text

    expect(text[0..13]).to eq(
      ["www.sac-cas.ch",
        "Teilnehmerliste",
        "Kursnummer",
        "10",
        "Bezeichnung",
        "Tourenleiter/in 1 Sommer",
        "Kursort",
        "Berghotel Schwarenbach, 3752 Kandersteg",
        "Datum",
        "Mi 01.03.2023, Mo 03.04.2023 - Mo 10.04.2023",
        "Anzahl Teilnehmende",
        "2",
        "Anzahl Kurskader",
        "3"]
    )
    expect(text[14..23]).to eq(
      ["Mitglieder-Nr.",
        "Vorname",
        "Nachname",
        "Strasse",
        "Wohnort",
        "E-Mail",
        "Telefonnummer",
        "Sprache",
        "Geschlecht",
        "Sektion"]
    )

    expect(text[24..43]).to eq(
      ["600001",
        "Edmund",
        "Hillary",
        "Ophovenerstrasse 79a",
        "2843 Neu Carlscheid",
        "e.hillary@hitobito.example.com",
        "+41 77 484 21 96",
        "Deutsch",
        "weiblich",
        "SAC Blüemlisalp",
        "600002",
        "Tenzing",
        "Norgay",
        "Ophovenerstrasse 79a",
        "2843 Neu Carlscheid",
        "t.norgay@hitobito.example.com",
        "+41 77 360 75 63",
        "Deutsch",
        "divers",
        "SAC Blüemlisalp"]
    )

    expect(text[44..60]).to eq(
      ["Kursleitung",
        @leaders.first.id.to_s,
        @leaders.first.first_name,
        @leaders.first.last_name,
        @leaders.first.address,
        [@leaders.first.zip_code, @leaders.first.town].join(" "),
        @leaders.first.email,
        "Deutsch",
        "divers",
        @leaders.last.id.to_s,
        @leaders.last.first_name,
        @leaders.last.last_name,
        @leaders.last.address,
        [@leaders.last.zip_code, @leaders.last.town].join(" "),
        @leaders.last.email,
        "Deutsch",
        "divers"]
    )

    expect(text[61..69]).to eq(
      ["Klassenleitung (Aspirant)",
        @aspirant.id.to_s,
        @aspirant.first_name,
        @aspirant.last_name,
        @aspirant.address,
        [@aspirant.zip_code, @aspirant.town].join(" "),
        @aspirant.email,
        "Deutsch",
        "divers"]
    )
  end
end
