#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::EventParticipationsExportJob do
  subject { Export::EventParticipationsExportJob.new(format, user.id, event.id, groups(:bluemlisalp).id, params.merge(filename: filename)) }

  let!(:participation) { event_participations(:top_mitglied) }
  let(:user) { participation.person }
  let(:event) { participation.event }
  let(:filename) { AsyncDownloadFile.create_name("event_participation_export", user.id) }

  let(:params) { {} }

  let(:file) do
    AsyncDownloadFile
      .from_filename(filename, format)
  end

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]
  end

  context "creates a course data export" do
    let(:format) { :csv }
    let(:params) { {course_data: true, filter: "all"} }

    it "and saves it" do
      subject.perform
      
      lines = file.read.lines
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Veranstaltungsnummer;Kursortname;Kursbezeichnung;Anfangsdatum;Enddatum;Teilnehmernummer;Geschlecht;Familienname;Vorname;Sprachcode;Adresse;PLZ;Ort;Sektionsname;Geburtsdatum;Haupt-E-Mail.*/)
      expect(lines[1..-1]).to match_array([
        /10;Bern, Zurich;Tourenleiter\/in 1 Sommer;01.03.2023 00:00;10.04.2023 00:00;600001;weiblich;Hillary;Edmund/,
        /10;Bern, Zurich;Tourenleiter\/in 1 Sommer;01.03.2023 00:00;10.04.2023 00:00;600002;divers;Norgay;Tenzing/
      ])
    end

    context "creates an Excel-Export" do
      let(:format) { :xlsx }

      it "and saves it" do
        subject.perform

        expect(file.generated_file).to be_attached
      end
    end
  end
end
