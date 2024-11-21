# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::Participations::CourseDataRow do
  let(:stammsektion) { groups(:bluemlisalp) }
  let(:participation) { event_participations(:top_mitglied) }

  let!(:event) do
    event = participation.event

    I18n.with_locale(:fr) do
      event.update!(name: "Chef de tournée")
    end

    I18n.with_locale(:it) do
      event.update!(name: "Accompagnatore turistico")
    end

    event
  end

  subject(:row) { described_class.new(participation) }

  def value(key) = row.fetch(key)

  it("event_number") { expect(value(:event_number)).to eq "10" }
  it("event_dates_locations") { expect(value(:event_dates_locations)).to eq "Bern, Zurich" }
  it("event_first_date") { expect(value(:event_first_date)).to eq event_dates(:first).start_at.strftime("%d.%m.%Y %H:%M") }
  it("event_last_date") { expect(value(:event_last_date)).to eq event_dates(:first_two).finish_at.strftime("%d.%m.%Y %H:%M") }
  it("person_id") { expect(value(:person_id)).to eq 600001 }
  it("person_gender") { expect(value(:person_gender)).to eq "weiblich" }
  it("person_last_name") { expect(value(:person_last_name)).to eq "Hillary" }
  it("person_first_name") { expect(value(:person_first_name)).to eq "Edmund" }
  it("person_address") { expect(value(:person_address)).to eq "Ophovenerstrasse 79a" }
  it("person_zip_code") { expect(value(:person_zip_code)).to eq "2843" }
  it("person_town") { expect(value(:person_town)).to eq "Neu Carlscheid" }
  it("person_birthday") { expect(value(:person_birthday)).to eq Date.new(2000, 1, 1).strftime("%d.%m.%Y") }
  it("person_email") { expect(value(:person_email)).to eq "e.hillary@hitobito.example.com" }
  it("person_stammsektion") { expect(value(:person_stammsektion)).to eq "#{stammsektion.id} #{stammsektion.name}" }

  context "with german person language" do
    before { participation.person.update!(language: :de) }

    it("person_language_code") { expect(value(:person_language_code)).to eq "DES" }
  end

  context "with french person language" do
    before { participation.person.update!(language: :fr) }

    it("person_language_code") { expect(value(:person_language_code)).to eq "FRS" }
  end

  context "with italian person language" do
    before { participation.person.update!(language: :it) }

    it("person_language_code") { expect(value(:person_language_code)).to eq "ITS" }
  end

  context "with german course language" do
    before { event.update!(language: :de) }

    it("person_gender") { expect(value(:person_gender)).to eq "weiblich" }
    it("event_name") { expect(value(:event_name)).to eq "Tourenleiter/in 1 Sommer" }
  end

  context "with german/french course language" do
    before { event.update!(language: :de_fr) }

    it("person_gender") { expect(value(:person_gender)).to eq "weiblich" }
    it("event_name") { expect(value(:event_name)).to eq "Tourenleiter/in 1 Sommer" }
  end

  context "with french course language" do
    before { event.update!(language: :fr) }

    it("person_gender") { expect(value(:person_gender)).to eq "féminin" }
    it("event_name") { expect(value(:event_name)).to eq "Chef de tournée" }
  end

  context "with italian course language" do
    before { event.update!(language: :it) }

    it("person_gender") { expect(value(:person_gender)).to eq "donna" }
    it("event_name") { expect(value(:event_name)).to eq "Accompagnatore turistico" }
  end
end
