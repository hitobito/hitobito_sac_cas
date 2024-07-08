# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Pdf::Passes::Membership do
  include PdfHelpers

  let(:member) do
    person = Fabricate(:person, birthday: Time.zone.today - 42.years)
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
      person: person,
      group: groups(:bluemlisalp_mitglieder))
    Person.with_membership_years.find(person.id)
  end
  let(:pdf) { subject.render }
  let(:analyzer) { PDF::Inspector::Text.analyze(pdf) }
  let(:page_analysis) { PDF::Inspector::Page.analyze(pdf) }
  let(:year) { Time.zone.now.year }

  subject { described_class.new(member) }

  before do
    member.update!(first_name: "Bob", last_name: "Muster", street: "Bergstrasse", housenumber: "42", zip_code: "4242", town: "Matterhorn")
  end

  it "sanitizes filename" do
    expect(subject.filename).to eq "SAC-Mitgliederausweis-#{year}-bob_muster.pdf"
  end

  it "has one page" do
    expect(page_analysis.pages.size).to eq(1)
  end

  context "text" do
    let(:texts) {
      [
        [65, 705, "#{member.first_name} #{member.last_name}"],
        [65, 694, "Bergstrasse 42"],
        [65, 684, "4242 Matterhorn"],
        [160, 96, "Bob Muster"],
        [160, 74, "Mitglied: #{member.membership_number}"],
        [61, 148, "Mitgliederausweis"],
        [510, 83, "SAC-Partner"],
        [309, 182, "REGA 1414                    SOS Europe 112"],
        [311, 168, "Notfallnummer / N° d'urgence / No. di emergenza"],
        [311, 137, "Notfallkontakt / Contact d'urgence / Contatto di emergenza"],
        [490, 148, "www.sac-cas.ch"]
      ]
    }

    let(:texts_fr) {
      texts.dup.tap { |x|
        x[4][2] = "Membre: #{member.membership_number}"
        x[5][2] = "Carte membre"
        x[6] = [506, 83, "Partenaire CAS"]
      }
    }

    let(:texts_it) {
      texts.dup.tap { |x|
        x[4][2] = "Membro: #{member.membership_number}"
        x[5][2] = "Tessera di Membro"
        x[6] = [510, 83, "Partner CAS"]
      }
    }

    let(:expected_image_positions) {
      [{x: 141.208, y: 130.585, width: 721, height: 301, displayed_width: 103520.459, displayed_height: 18047.057},
        {x: 47.0, y: 37.0, width: 70, height: 70, displayed_width: 7000.0, displayed_height: 7700.0},
        {x: 14.0, y: 193.3, width: 640, height: 384, displayed_width: 12800.0, displayed_height: 4608.0},
        {x: 496.714, y: 157.55607, width: 458, height: 375, displayed_width: 18267.329999999998, displayed_height: 12246.348750000001},
        {x: 499.0, y: 33.126, width: 70, height: 70, displayed_width: 3850.0, displayed_height: 3850.0}]
    }

    it "renders membership pass" do
      expect(text_with_position(analyzer)).to match_array texts
    end

    it "renders membership pass images" do
      expect(image_positions).to match_array expected_image_positions
    end

    it "renders membership pass in french" do
      I18n.with_locale(:fr) do
        expect(text_with_position(analyzer)).to match_array texts_fr
      end
    end

    it "renders membership pass in italian" do
      I18n.with_locale(:it) do
        expect(text_with_position(analyzer)).to match_array texts_it
      end
    end

    it "has german logo" do
      I18n.with_locale(:de) do
        sections = subject.send(:sections)
        logo_path = sections[0].logo_path
        expect(logo_path.to_s).to include("_de_")
        expect(image_included_in_images?(logo_path)).to be(true)
      end
    end

    it "has french logo" do
      german_logo = subject.send(:sections)[0].logo_path

      I18n.with_locale(:fr) do
        logo_path = subject.send(:sections)[0].logo_path
        expect(logo_path.to_s).to include("_fr_")
        expect(image_included_in_images?(logo_path)).to be(true)
        expect(image_included_in_images?(german_logo)).to be(false)
      end
    end
  end

  context "longer text" do
    let(:texts) {
      [
        [61, 148, "Mitgliederausweis"],
        [65, 621, "4242 Matterhorn"],
        [65, 632, "Bergstrasse 42"],
        [65, 642, "Chokyumei-no Chosuke"],
        [65, 653, "no Ponpokopii-no Ponpokona-no"],
        [65, 663, "Shuringan Shuringan-no Gurindai Gurindai-"],
        [65, 673, "Yaburakoji-no Burakoji Paipopaipo Paipo-no"],
        [65, 684, "Furaimatsu Kuunerutokoro-ni Sumutokoro"],
        [65, 694, "Kaijarisuigyo-no Suigyomatsu Unraimatsu"],
        [65, 705, "Jugemu Jugemu Goko-no Surikire"],
        [160, 57, "Mitglied: #{member.membership_number}"],
        [160, 69, "no Ponpokona-no Chokyumei-no Chosuke"],
        [160, 75, "Shuringan-no Gurindai Gurindai-no Ponpokopii-"],
        [160, 81, "Burakoji Paipopaipo Paipo-no Shuringan"],
        [160, 87, "Kuunerutokoro-ni Sumutokoro Yaburakoji-no"],
        [160, 92, "no Suigyomatsu Unraimatsu Furaimatsu"],
        [160, 98, "Jugemu Jugemu Goko-no Surikire Kaijarisuigyo-"],
        [309, 182, "REGA 1414                    SOS Europe 112"],
        [311, 137, "Notfallkontakt / Contact d'urgence / Contatto di emergenza"],
        [311, 168, "Notfallnummer / N° d'urgence / No. di emergenza"],
        [490, 148, "www.sac-cas.ch"],
        [510, 83, "SAC-Partner"]
      ]
    }

    before do
      member.first_name = %w[Jugemu Jugemu Goko-no Surikire Kaijarisuigyo-no
        Suigyomatsu Unraimatsu Furaimatsu Kuunerutokoro-ni Sumutokoro Yaburakoji-no Burakoji Paipopaipo].join(" ")
      member.last_name = %w[Paipo-no Shuringan Shuringan-no Gurindai Gurindai-no Ponpokopii-no
        Ponpokona-no Chokyumei-no Chosuke].join(" ")
      member.save
    end

    it "supports longer names" do
      expect(text_with_position(analyzer)).to match_array texts
    end
  end

  context "country" do
    before do
      member.update!(country: "DE")
    end

    it "does include the countries name in full" do
      expect(text_with_position(analyzer).flatten).to include "Deutschland"
    end

    it "does translate the country" do
      I18n.with_locale(:fr) do
        expect(text_with_position(analyzer).flatten).to include "Allemagne"
      end
    end

    it "does not include Switzerland" do
      member.update!(country: "CH")
      texts = text_with_position(analyzer).flatten
      expect(texts).not_to include "Schweiz"
      expect(texts).not_to include "CH"
    end
  end

  private

  def extract_image_objects(page_no = 1)
    rendered_pdf = pdf.try(:render) || pdf
    io = StringIO.new(rendered_pdf)

    PDF::Reader.open(io) do |reader|
      page = reader.page(page_no)

      # Extract all XObjects of type :Image from the page
      page.xobjects.select { |_, obj| obj.hash[:Subtype] == :Image }.to_a.map { |item|
        Digest::MD5.hexdigest(item[1].data)
      }
    end
  end

  def image_included_in_images?(image_path)
    image_data = Digest::MD5.hexdigest(File.binread(image_path))
    extract_image_objects.include?(image_data)
  end
end
