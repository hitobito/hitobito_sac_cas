# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances do
  let(:table) { described_class.new(2025) }

  it "has expected attributes" do
    expect(table.attributes).to eq [
      :event_kind_category_order,
      :event_kind_category_label,
      :event_kind_short_name,
      :event_kind_label,
      :season,
      :name,
      :number,
      :start_on,
      :finish_on,
      :state,
      :language,
      :closed_month,
      :total_revenue,
      :leader_count,
      :leader_compensations,
      :minimum_participants,
      :maximum_participants,
      :attended_count,
      :absent_count,
      :price_member,
      :price_member_count,
      :price_regular,
      :price_regular_count,
      :price_subsidized,
      :price_subsidized_count,
      :price_special,
      :price_special_count,
      :age_0_17_count,
      :age_18_22_count,
      :age_23_35_count,
      :age_36_50_count,
      :age_51_60_count,
      :age_61__count,
      :sac_member_count,
      :non_sac_member_count
    ]
  end

  it "has expected labels" do
    expect(table.labels).to eq [
      "Kurskategorie",
      "Kurskategoriename",
      "Kursart Kurzname",
      "Kursart Verbandsbezeichnung",
      "Saison",
      "Kursname",
      "Kursnummer",
      "Startdatum",
      "Enddatum",
      "Kursstatus",
      "Sprache",
      "Kursabschluss Monat",
      "Kursumsatz CHF",
      "Grösse Leitungsteam",
      "Honorare Leitungsteam Summe",
      "Minimale Teilnehmerzahl",
      "Maximale Teilnehmerzahl",
      "Anzahl effektive Teilnehmende",
      "Anzahl nicht erschienene Teilnehmende",
      "Mitgliederpreis",
      "Anzahl TN Mitgliederpreis",
      "Normalpreis",
      "Anzahl TN Normalpreis",
      "Subventionierter Preis",
      "Anzahl TN Subventionierter Preis",
      "Spezialpreis",
      "Anzahl TN Spezialpreis",
      "Anzahl TN Altersgruppe 0-17 Jahre",
      "Anzahl TN Altersgruppe 18-22 Jahre",
      "Anzahl TN Altersgruppe 23-35 Jahre",
      "Anzahl TN Altersgruppe 36-50 Jahre",
      "Anzahl TN Altersgruppe 51-60 Jahre",
      "Anzahl TN Altersgruppe 61+ Jahre",
      "Anzahl TN SAC Mitglieder",
      "Anzahl TN Nicht SAC Mitglieder"
    ]
  end

  describe "#event_scope" do
    subject(:event_scope) { table.send(:event_scope) }

    it "contains only closed courses in the given year" do
      course1 = Fabricate(:sac_open_course, state: :closed,
        dates_attributes: [{start_at: "2025-05-01", finish_at: "2025-05-05"}])
      _too_early = Fabricate(:sac_open_course, state: :closed,
        dates_attributes: [{start_at: "2024-12-21", finish_at: "2024-12-31"}])
      _too_late = Fabricate(:sac_open_course, state: :closed,
        dates_attributes: [{start_at: "2026-01-01", finish_at: "2026-01-05"}])
      _not_closed = Fabricate(:sac_open_course, state: :ready,
        dates_attributes: [{start_at: "2025-05-01", finish_at: "2025-05-05"}])
      _other_type = Fabricate(:sac_published_tour, state: :closed,
        dates_attributes: [{start_at: "2025-05-01", finish_at: "2025-05-05"}])
      expect(event_scope).to eq([course1])
    end
  end

  describe "data_rows" do
    let(:row_class) do
      Data.define(*described_class.attributes) do
        def to_s = name
      end
    end
    let(:rows) { table.data_rows.map { |r| row_class.new(*r) } }

    before do
      @cat = Fabricate(:course_compensation_category, leader_settlement: true, kind: :day)
      @rate = @cat.course_compensation_rates.create!(
        rate_leader: 50,
        rate_assistant_leader: 45,
        rate_leader_aspirant: 30,
        rate_assistant_leader_aspirant: 25,
        valid_from: "2020-01-01"
      )
      event_kinds(:slk).course_compensation_categories << @cat

      course1 = Fabricate(:sac_open_course,
        state: :closed,
        number: "2025-0042",
        minimum_participants: 5,
        maximum_participants: 10,
        price_member: 125.20,
        price_regular: 158,
        price_subsidized: 80,
        price_special: nil,
        dates_attributes: [{start_at: "2025-05-01", finish_at: "2025-05-05"}]).tap do |course|
          course.update_column(:closed_at, "2025-10-15")
        end

      Fabricate(:event_participation,
        event: course1,
        actual_days: 5,
        roles: [Fabricate.build(:"Event::Course::Role::Leader")])
      Fabricate(:sac_open_course, state: :closed,
        dates_attributes: [{start_at: "2025-06-28", finish_at: "2025-07-06"}]).tap do |course|
          course.update_column(:closed_at, "2025-09-20")
        end

      attended1 = Fabricate(:event_participation,
        event: course1,
        actual_days: 5,
        state: "attended",
        price_category: "price_member",
        price: 125.20,
        roles: [Fabricate.build(:"Event::Course::Role::Participant")])
      ExternalInvoice::CourseParticipation.create!(
        person: attended1.person,
        state: :payed,
        link: attended1,
        total: 125.20
      )
      ExternalInvoice::CourseParticipation.create!(
        person: attended1.person,
        state: :cancelled,
        link: attended1,
        total: 155.80
      )
      attended1.person.update!(birthday: 20.years.ago)

      attended2 = Fabricate(:event_participation,
        event: course1,
        actual_days: 5,
        state: "attended",
        price_category: "price_regular",
        price: 155.80,
        roles: [Fabricate.build(:"Event::Course::Role::Participant")])
      attended2.person.update!(birthday: 40.years.ago)

      canceled = Fabricate(:event_participation,
        event: course1,
        state: "canceled",
        canceled_at: 2.weeks.ago,
        price_category: "price_member",
        price: 125.20,
        roles: [Fabricate.build(:"Event::Course::Role::Participant")])
      ExternalInvoice::CourseAnnulation.create!(
        person: canceled.person,
        state: :payed,
        link: canceled,
        total: 42.0
      )
      canceled.person.update!(birthday: 50.years.ago)

      absent = Fabricate(:event_participation,
        event: course1,
        actual_days: 0,
        state: "absent",
        price_category: "price_subsidized",
        price: 100,
        roles: [Fabricate.build(:"Event::Course::Role::Participant")])
      absent.person.update!(birthday: 55.years.ago)
    end

    it "does not do N+1 queries" do
      Group.root_id # force eager loading
      expect do
        expect(table.data_rows).to have(2).items
      end.to make(13).db_queries
    end

    it "contains all attributes" do
      expect(rows.first.to_h).to eq({
        event_kind_category_order: nil,
        event_kind_category_label: "Ski Technik Kurs",
        event_kind_label: "Schneeleiterkurs",
        event_kind_short_name: "SLK",
        season: "Winter",
        name: "Eventus",
        number: "2025-0042",
        start_on: "01.05.2025",
        finish_on: "05.05.2025",
        state: "Abgeschlossen",
        language: "de",
        closed_month: "2025-10",
        total_revenue: 125.2,
        leader_count: 1,
        leader_compensations: 250.0,
        minimum_participants: 5,
        maximum_participants: 10,
        attended_count: 2,
        absent_count: 1,
        price_member: 125.20,
        price_member_count: 1,
        price_regular: 158.0,
        price_regular_count: 1,
        price_subsidized: 80,
        price_subsidized_count: 0,
        price_special: nil,
        price_special_count: 0,
        age_0_17_count: 0,
        age_18_22_count: 1,
        age_23_35_count: 0,
        age_36_50_count: 1,
        age_51_60_count: 0,
        age_61__count: 0,
        sac_member_count: 0,
        non_sac_member_count: 2
      })
    end
  end
end
