# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Nav18EventsImporter do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:output) { double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav18-events_2024-01-23-1142.csv") }
  let(:report_headers) {
    %w[number name_de status errors]
  }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    File.delete(report_file) if File.exist?(report_file)
    stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)

    load(HitobitoSacCas::Wagon.root.join("db", "seeds", "course_master_data.rb"))
    seed_cost_centers
    seed_cost_units
    seed_event_kind_categories
    seed_event_levels
    seed_course_compensation_categories
    create_event_kinds
  end

  it "creates report for entries in source file" do
    expected_output = []
    expected_output << "Alpinwandern (2012-5750): ❌ Unterkunft muss ausgefüllt werden, Kostenstelle muss ausgefüllt werden"
    expected_output << "Wettkampfklettern - Schiedsrichter/in national (2013-2701): ❌ Kursart muss ausgefüllt werden"

    expect(output).to receive(:puts).with("The file contains 6 rows.")
    expected_output.flatten.each do |output_line|
      expect(output).to receive(:puts).with(output_line)
    end
    expect(output).to receive(:puts).with("\n\n\nReport generated in 0.0 minutes.")
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    expect { report.create }
      .to change { Event::Course.count }.by(4).and \
        change { Event::Date.count }.by(4)

    course = Event::Course.find_by(number: "2023-1460")
    expect(course.attributes.symbolize_keys).to include(
      type: "Event::Course",
      number: "2023-1460",
      maximum_participants: 12,
      contact_id: 600000,
      location: "Grubenberghütte",
      application_opening_at: Date.new(2023, 2, 21),
      application_closing_at: Date.new(2023, 2, 21),
      state: "closed",
      external_applications: true,
      signature: false,
      signature_confirmation: false,
      notify_contact_on_participations: false,
      training_days: 2,
      minimum_participants: 4,
      automatic_assignment: false,
      language: "de_fr",
      annual: false,
      link_participants: "https://cloud.sac-cas.ch/s/592y6aoGKMFWnMQ",
      link_leaders: "https://cloud.sac-cas.ch/f/92175",
      link_survey: "https://www.umfrageonline.ch/s/i4tkdxf",
      accommodation: "hut",
      reserve_accommodation: false,
      season: "winter",
      start_point_of_time: "day",
      minimum_age: 18,
      meals: "half_board",
      book_discount_code: nil,
      ideal_class_size: 6,
      maximum_class_size: 6,
      maximum_age: 0,
      price_member: 0.0,
      price_regular: 0.0,
      name: "Alpine Umwelt",
      application_conditions: "gute allgemeine Kondition für eine Wintertour in den Bergen mit Schneeschuhen",
      description: "Im Winter scheint die Natur in den Bergen zu schlafen, eingehüllt in Schnee und Eis. Aber die Natur lebt, oder besser gesagt, überlebt im harschen, winterlichen Klima der Berge. Ein Klima aber, das immer wärmer wird, vor allem in den Bergen, stellt die Natur vor neue Herausforderungen. Was für Wildtierspuren können wir entdecken? Welche Strategien haben die Tiere, um den Winter zu überleben? Und vor allem: Wie verhalten wir uns beim Schneesport rücksichtsvoll gegenüber den Alpentieren, die im Winter besonders empfindlich auf Störungen reagieren und sich zudem an die Folgen des Klimawandels anpassen müssen? Dieser Kurs hilft dir, die Alpentiere im Winter kennen zu lernen und zeigt, was den natur- und umweltverträglichen Schneesport ausmacht.",
      signature_confirmation_text: "Erziehungsberechtigte Person (bei Minderjährigen)",
      brief_description: "Dieser Sensibilisierungskurs für die alpine Umwelt im Winter richtet den Fokus auf Alpentiere und Schneesport mit Rücksicht auf Natur und Umwelt. Er findet im Rahmen einer Schneeschuhtour statt.",
      specialities: nil,
      similar_tours: nil,
      program: nil
    )
    expect(course.kind.short_name).to eq("S1460")
    expect(course.cost_center.code).to eq("2100026")
    expect(course.cost_unit.code).to eq("A1300")
    expect(course.dates.size).to eq(1)
    expect(course.dates.first.start_at).to eq(Time.zone.local(2023, 3, 11, 8))
    expect(course.dates.first.finish_at).to eq(Time.zone.local(2023, 3, 12, 17))
    I18n.with_locale(:fr) do
      expect(course.name).to eq("Environnement alpin")
      expect(course.description).to eq("En hiver, en montagne, la nature semble endormie, enveloppée de neige et de glace. En réalité, elle vit, ou plutôt survit, dans le climat rude et hivernal des montagnes. Toutefois, un climat qui se réchauffe de plus en plus, surtout en montagne, pose de nouveaux défis à la nature. Quelles traces d'animaux sauvages pouvons-nous repérer ? Quelles sont les stratégies des animaux pour survivre à l'hiver ? Et surtout : dans la pratique des sports de neige, comment pouvons-nous nous comporter de manière respectueuse envers les animaux alpins, lesquels sont particulièrement sensibles aux nuisances en hiver et doivent en outre s'adapter aux conséquences du changement climatique ? Ce cours t'aidera à mieux connaître les animaux alpins en hiver et te révélera ce qui caractérise des sports de neige respectueux de la nature et de l'environnement.")
    end
    I18n.with_locale(:it) do
      expect(course.name).to eq("Environnement alpin") # fallback to fr
    end

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(4)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report[1..3]).to eq(
      [["2012-5750", "Alpinwandern", "error", "Unterkunft muss ausgefüllt werden, Kostenstelle muss ausgefüllt werden"],
        ["2013-2701", "Wettkampfklettern - Schiedsrichter/in national", "warning", "kind with value S2700 couldn't be found"],
        ["2013-2701", "Wettkampfklettern - Schiedsrichter/in national", "error", "Kursart muss ausgefüllt werden"]]
    )

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end

  def create_event_kinds
    default_attrs = {
      cost_unit: CostUnit.find_by(code: "A1300"),
      cost_center: CostCenter.find_by(code: "2100026"),
      kind_category: Event::KindCategory.find_by(label: "Diverse Kurse Winter"),
      level: Event::Level.find_by(code: 1)
    }
    Fabricate(:event_kind, default_attrs.merge(label: "Alpin Umwelt", short_name: "S1460"))
    Fabricate(:event_kind, default_attrs.merge(label: "Alpin Umwelt", short_name: "S5760"))
    Fabricate(:event_kind, default_attrs.merge(label: "Alpinwandern", short_name: "S5750"))
  end
end
