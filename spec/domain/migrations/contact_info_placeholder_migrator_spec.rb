# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Migrations::ContactInfoPlaceholderMigrator do
  let(:migrator) { described_class.new }
  let(:group) { groups(:bluemlisalp) }
  let(:content) do
    group.custom_contents.create!(key: "event_tour_publication", label: "Tour: E-Mail Publikation",
      subject: "Publikation", body: "Text")
  end

  def localized(locale, subject: "Sujet", body: "Texte")
    I18n.with_locale(locale) do
      content.update!(subject:, body:)
      yield
      content.reload
      [content.subject, content.body.body.to_html]
    end
  end

  def rewrite(body, locale: :fr)
    localized(locale, body:) { migrator.rewrite_placeholders }.last
  end

  describe "#rewrite_placeholders" do
    it "replaces name and removes parentheses with contact details" do
      expect(rewrite("Questions: {contact-first-name} {contact-last-name} " \
                     "({contact-id}, {contact-phone}, {contact-email}).<br>Fin"))
        .to eq("Questions: {contact-info}.<br>Fin")
    end

    it "removes parentheses with reordered contact details" do
      expect(rewrite("Contact: {contact-first-name} {contact-last-name} " \
                     "({contact-email}, {contact-phone}, {contact-id})"))
        .to eq("Contact: {contact-info}")
    end

    it "keeps parentheses with contact id only" do
      expect(rewrite("{contact-first-name} {contact-last-name} ({contact-id})"))
        .to eq("{contact-info} ({contact-id})")
    end

    it "keeps contact name in parentheses" do
      expect(rewrite("Contact ({contact-first-name}, {contact-phone})"))
        .to eq("Contact ({contact-info})")
    end

    it "replaces single remaining contact placeholder" do
      expect(rewrite("Écris à {contact-email}.")).to eq("Écris à {contact-info}.")
    end

    it "removes further contact placeholders once contact-info is present" do
      expect(rewrite("Écris à {contact-email} ou appelle {contact-phone}."))
        .to eq("Écris à {contact-info} ou appelle.")
    end

    it "rewrites subject" do
      translated_subject, _ = localized(:it, subject: "Tour di {contact-first-name} {contact-last-name}") do
        migrator.rewrite_placeholders
      end

      expect(translated_subject).to eq("Tour di {contact-info}")
    end

    it "keeps texts without contact placeholders unchanged" do
      expect(rewrite("Texte {contact-id} {event-name}")).to eq("Texte {contact-id} {event-name}")
    end

    it "rewrites texts of every locale" do
      I18n.with_locale(:de) { content.update!(body: "Hallo {contact-email}") }

      expect(rewrite("Salut {contact-email}")).to eq("Salut {contact-info}")
      expect(I18n.with_locale(:de) { content.reload.body.body.to_html }).to eq("Hallo {contact-info}")
    end

    it "returns number of rewritten texts" do
      I18n.with_locale(:fr) { content.update!(subject: "{contact-email}", body: "{contact-phone}") }
      I18n.with_locale(:it) { content.update!(body: "Ciao") }

      expect(migrator.rewrite_placeholders).to eq(2)
    end
  end

  describe "#reset_section_templates" do
    let(:ortsgruppe) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

    before do
      [group, ortsgruppe].each do |g|
        CustomContent.init_section_specific_contents(g)
        g.custom_contents.where(key: %w[event_tour_publication event_tour_report_approved])
          .find_each { |c| c.update!(subject: "Eigener Betreff") }
      end
    end

    def subjects(key)
      [group, ortsgruppe].map { |g| g.custom_contents.find_by(key:).subject }
    end

    it "overwrites german templates using contact placeholders" do
      I18n.with_locale(:fr) { migrator.reset_section_templates }

      expect(subjects(:event_tour_publication)).to all eq("Publikation der Tour {event-name}")
      expect(group.custom_contents.find_by(key: :event_tour_publication).body.to_s)
        .to include("Bei Fragen kannst du dich jederzeit an {contact-info} wenden.")
      expect(subjects(:event_tour_report_approved)).to all eq("Eigener Betreff")
    end

    it "keeps other locales" do
      I18n.with_locale(:fr) do
        group.custom_contents.find_by(key: :event_tour_publication).update!(subject: "Sujet")
      end

      migrator.reset_section_templates

      expect(I18n.with_locale(:fr) { subjects(:event_tour_publication) }).to include("Sujet")
    end

    it "returns number of reset templates" do
      expect(migrator.reset_section_templates).to eq(2 * described_class::RESET_KEYS.size)
    end
  end
end
