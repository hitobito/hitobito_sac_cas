# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMembershipsMailer do
  include Households::SpecHelper

  let(:mitglied) { roles(:mitglied) }
  let(:person) { mitglied.person }
  let(:mail) {
    described_class.confirmation(person, mitglied.group.parent, mitglied.beitragskategorie)
  }

  it "sends confirmation email to person" do
    expect(mail.body.to_s).to include("Hallo Edmund,",
      "Vielen Dank für deine Zahlung, welche bei uns eingegangen ist.")
    expect(mail.body.to_s).to include(person_path(person))
  end

  it "considers person's language when sending" do
    CustomContent.get(Invoices::SacMembershipsMailer::MEMBERSHIP_ACTIVATED).update!(locale: :fr,
      label: "label", subject: "Acceptee", body: "Bonjour {first-name}")
    person.update!(language: :fr)
    expect(mail.subject).to eq("Acceptee")
    expect(mail.body.to_s).to include("Bonjour")
  end

  it "includes sektion and MV in bcc" do
    expect(mail.bcc).to match_array ["bluemlisalp@sac.ch", "mv@sac-cas.ch"]
  end

  it "includes additional placeholders" do
    CustomContent.get(Invoices::SacMembershipsMailer::MEMBERSHIP_ACTIVATED).update(locale: :de,
      label: "label", body: <<~TEXT)
        {first-name}
        {person-ids}
        {last-name}
        {birthday}
        {email}
        {phone-number}
        {address-care-of}
        {street-with-number}
        {postbox}
        {zip-code}
        {town}
        {country}
        {section-name}
        {membership-category}
        {invoice-details}
        {faq-url}
        {profile-url}
        {profile-links}
      TEXT

    expect(mail.body).to include("Edmund")
    expect(mail.body).to include("600001")
    expect(mail.body).to include("Hillary")
    expect(mail.body).to include("01.01.2000")
    expect(mail.body).to include("e.hillary@hitobito.example.com")
    expect(mail.body).to include("Ophovenerstrasse 79a")
    expect(mail.body).to include("CH")
    expect(mail.body).to include("SAC Blüemlisalp")
    expect(mail.body).to include("Einzel")
    expect(mail.body).to include("Total erstmalig")
    expect(mail.body).to include("https://www.sac-cas.ch/de/meta/faq/mitgliedschaft")
    expect(mail.body).to include(person_path(person))
    expect(mail.body).to include(person_url(person))
    expect(mail.body).to include(person.full_name)
  end

  it "profile-links placeholder includes links to all household members" do
    create_household(person, Fabricate(:person), Fabricate(:person, birthday: 12.years.ago))

    CustomContent.get(Invoices::SacMembershipsMailer::MEMBERSHIP_ACTIVATED).update(locale: :de,
      label: "label", body: "{first-name} {profile-links}")

    person.household.people.each do |household_person|
      expect(mail.body).to include(person_url(household_person))
      expect(mail.body).to include(household_person.full_name)
    end
  end
end
