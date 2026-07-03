# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_context "alps recipients test data" do
  let(:sektion) { groups(:bluemlisalp_mitglieder) }

  let(:abo_de) { groups(:abo_die_alpen) }
  let!(:abo_fr) { Group::AboMagazin.create!(name: "Les Alps FR", parent: groups(:abo_magazine)) }
  let!(:abo_it) { Group::AboMagazin.create!(name: "Le Alpi IT", parent: groups(:abo_magazine)) }

  let!(:mitglied) { people(:mitglied) }
  let!(:mitglied_germany) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, country: "DE", zip_code: "12345"),
      group: sektion,
      start_on: "2020-03-23").person
  end
  let!(:mitglied_germany_fr) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, country: "DE", zip_code: "12345", language: "fr"),
      group: sektion,
      start_on: "2020-03-24").person
  end
  let!(:mitglied_fr) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, language: "fr"),
      group: sektion,
      start_on: "2020-03-25").person
  end
  let!(:mitglied_france) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, language: "fr", country: "FR", zip_code: "12345"),
      group: sektion,
      start_on: "2020-03-26").person
  end
  let!(:mitglied_with_excluded_subscription) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2020-03-27").person
    mailing_lists(:sac_magazine).subscriptions.create!(subscriber: p, excluded: true)
    p
  end
  let!(:new_entry) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2025-07-20").person
  end
  let!(:new_entry_fr) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, language: "fr"),
      group: sektion,
      start_on: "2025-07-21").person
  end
  let!(:new_entry_germany) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, country: "DE", zip_code: "12345"),
      group: sektion,
      start_on: "2025-07-22").person
  end
  let!(:new_entry_france) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      person: Fabricate(:person, language: "fr", country: "FR", zip_code: "12345"),
      group: sektion,
      start_on: "2025-07-23").person
  end
  let!(:new_entry_with_old_membership) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2015-09-28",
      end_on: "2021-12-31").person
    Fabricate("Group::SektionsMitglieder::Mitglied",
      person: p,
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2025-08-15")
    p
  end
  let!(:beitragskategoriewechsel) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :youth,
      group: sektion,
      start_on: "2022-05-18",
      end_on: "2025-08-20").person
    Fabricate("Group::SektionsMitglieder::Mitglied",
      person: p,
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2025-08-21")
    p
  end
  let!(:sektionswechsel_before_new_entries_from) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: groups(:matterhorn_mitglieder),
      start_on: "2020-02-12",
      end_on: "2024-04-24").person
    Fabricate("Group::SektionsMitglieder::Mitglied",
      person: p,
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2024-04-25")
    p
  end
  let!(:terminated) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2023-10-10",
      end_on: "2025-07-31").person
  end
  let!(:future) do
    Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2025-11-01").person
  end
  let!(:magazin_abonnent) do
    people(:abonnent)
  end
  let!(:magazin_abonnent_company) do
    Fabricate("Group::AboMagazin::Abonnent",
      group: abo_de,
      person: Fabricate(:person,
        language: "fr",
        first_name: nil,
        last_name: nil,
        birthday: nil,
        company_name: "My Company",
        company: true),
      start_on: "2021-08-01").person
  end
  let!(:magazin_abonnent_germany) do
    Fabricate("Group::AboMagazin::Abonnent",
      group: abo_de,
      person: Fabricate(:person, country: "DE", zip_code: "12345"),
      start_on: "2021-08-02").person
  end
  let!(:magazin_abonnent_germany_fr) do
    Fabricate("Group::AboMagazin::Abonnent",
      group: abo_fr,
      person: Fabricate(:person, country: "DE", zip_code: "12345"),
      start_on: "2021-08-03").person
  end
  let!(:new_entry_abonnent_fr) do
    Fabricate("Group::AboMagazin::Gratisabonnent",
      group: abo_fr,
      start_on: "2025-06-15").person
  end
  let!(:new_entry_abonnent_france) do
    Fabricate("Group::AboMagazin::Abonnent",
      group: abo_fr,
      person: Fabricate(:person, language: "de", country: "FR", zip_code: "12345"),
      start_on: "2025-06-15").person
  end
  let!(:new_entry_abonnent_with_old_abo) do
    p = Fabricate("Group::AboMagazin::Abonnent",
      group: abo_de,
      start_on: "2023-01-11",
      end_on: "2024-12-31").person
    Fabricate("Group::AboMagazin::Abonnent",
      person: p,
      group: abo_de, start_on: "2025-06-15")
    p
  end
  let!(:mitglied_and_abonnent) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2022-04-22").person
    Fabricate("Group::AboMagazin::Abonnent",
      person: p,
      group: abo_de,
      start_on: "2025-07-01")
    p
  end
  let!(:old_mitglied_new_abonnent_fr) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2022-04-22",
      end_on: "2025-02-28").person
    Fabricate("Group::AboMagazin::Abonnent",
      person: p,
      group: abo_fr,
      start_on: "2025-03-01")
    p
  end
  let!(:new_entry_mitglied_de_and_abonnent_fr) do
    p = Fabricate("Group::SektionsMitglieder::Mitglied",
      beitragskategorie: :adult,
      group: sektion,
      start_on: "2025-04-23").person
    Fabricate("Group::AboMagazin::Abonnent",
      person: p,
      group: abo_fr,
      start_on: "2022-04-11")
    p
  end
  let!(:abonnent_de_and_fr) do
    p = Fabricate("Group::AboMagazin::Abonnent",
      group: abo_de,
      start_on: "2023-03-07").person
    Fabricate("Group::AboMagazin::Abonnent",
      person: p,
      group: abo_fr,
      start_on: "2025-03-03")
    p
  end

  let(:people_map) do
    [
      :mitglied,
      :mitglied_germany,
      :mitglied_germany_fr,
      :mitglied_fr,
      :mitglied_france,
      :mitglied_with_excluded_subscription,
      :new_entry,
      :new_entry_fr,
      :new_entry_germany,
      :new_entry_france,
      :new_entry_with_old_membership,
      :beitragskategoriewechsel,
      :sektionswechsel_before_new_entries_from,
      :terminated,
      :future,
      :magazin_abonnent,
      :magazin_abonnent_company,
      :magazin_abonnent_germany,
      :magazin_abonnent_germany_fr,
      :new_entry_abonnent_fr,
      :new_entry_abonnent_france,
      :new_entry_abonnent_with_old_abo,
      :mitglied_and_abonnent,
      :old_mitglied_new_abonnent_fr,
      :new_entry_mitglied_de_and_abonnent_fr,
      :abonnent_de_and_fr
    ].index_by { |key| send(key).id }
  end

  def expect_people(scope, keys)
    expect(map_people_keys(scope.pluck(:id))).to match_array(keys)
  end

  def map_people_keys(ids)
    ids.map { |id| people_map[id] || id }
  end
end
