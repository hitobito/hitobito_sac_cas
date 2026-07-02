# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "alps_recipients_test_data"

describe Export::Tabular::People::AlpsRecipientsScope do
  let(:reference_date) { Date.new(2025, 10, 1) }
  let(:new_entries_from) { nil }
  let(:scope) { described_class.new(reference_date, new_entries_from) }

  include_context "alps recipients test data"

  context "without new entries" do
    context "#regular" do
      it "contains all de people" do
        expect(map_people_keys(scope.regular(:de).pluck(:id))).to match_array([
          :mitglied,
          :new_entry,
          :new_entry_with_old_membership,
          :beitragskategoriewechsel,
          :sektionswechsel_before_new_entries_from,
          :magazin_abonnent,
          :magazin_abonnent_company,
          :new_entry_abonnent_with_old_abo,
          :mitglied_and_abonnent,
          :abonnent_de_and_fr,
          :new_entry_mitglied_de_and_abonnent_fr,
          people(:familienmitglied).id
        ])
      end

      it "contains all fr people" do
        expect(map_people_keys(scope.regular(:fr).pluck(:id))).to match_array([
          :mitglied_fr,
          :mitglied_france,
          :mitglied_germany_fr,
          :abonnent_de_and_fr,
          :new_entry_mitglied_de_and_abonnent_fr,
          :old_mitglied_new_abonnent_fr,
          :new_entry_fr,
          :new_entry_france,
          :new_entry_abonnent_fr,
          :new_entry_abonnent_france
        ])
      end

      it "contains no it people" do
        expect(map_people_keys(scope.regular(:it).pluck(:id))).to match_array([])
      end
    end

    context "#germany" do
      it "contains all german people" do
        expect(map_people_keys(scope.germany.pluck(:id))).to match_array([
          :mitglied_germany,
          :new_entry_germany,
          :magazin_abonnent_germany
        ])
      end
    end

    context "#all" do
      it "contains all people" do
        expect(map_people_keys(scope.all.pluck(:id))).to match_array([
          *people_map.values - [:terminated, :future, :mitglied_with_excluded_subscription],
          people(:familienmitglied).id
        ])
      end
    end
  end

  context "with new entries" do
    let(:new_entries_from) { Date.new(2025, 1, 1) }

    it "includes all people exactly once" do
      regulars = {}
      new_entries = {}
      [:de, :fr, :it].each do |lang|
        regulars[lang] = map_people_keys(scope.regular(lang).pluck(:id))
        new_entries[lang] = map_people_keys(scope.new_entries(lang).pluck(:id))
      end
      germans = map_people_keys(scope.germany.pluck(:id))
      all = map_people_keys(scope.all.pluck(:id))

      # people with two abonnements are only included once in `all`
      expect(regulars.values.flatten + new_entries.values.flatten + germans)
        .to match_array(all + [:abonnent_de_and_fr, :new_entry_mitglied_de_and_abonnent_fr])
    end

    context "#regular" do
      it "contains all de people without swiss new entries" do
        expect(map_people_keys(scope.regular(:de).pluck(:id))).to match_array([
          :mitglied,
          :beitragskategoriewechsel,
          :sektionswechsel_before_new_entries_from,
          :magazin_abonnent,
          :magazin_abonnent_company,
          :abonnent_de_and_fr,
          people(:familienmitglied).id
        ])
      end

      it "contains all fr people including french new entries" do
        expect(map_people_keys(scope.regular(:fr).pluck(:id))).to match_array([
          :mitglied_fr,
          :mitglied_france,
          :mitglied_germany_fr,
          :new_entry_france,
          :new_entry_abonnent_france,
          :new_entry_mitglied_de_and_abonnent_fr
        ])
      end

      it "contains no it people" do
        expect(map_people_keys(scope.regular(:it).pluck(:id))).to match_array([])
      end
    end

    context "#germany" do
      it "contains all german people including new entries" do
        expect(map_people_keys(scope.germany.pluck(:id))).to match_array([
          :mitglied_germany,
          :new_entry_germany,
          :magazin_abonnent_germany
        ])
      end
    end

    context "#all" do
      it "contains all people" do
        expect(map_people_keys(scope.all.pluck(:id))).to match_array([
          *people_map.values - [:terminated, :future, :mitglied_with_excluded_subscription],
          people(:familienmitglied).id
        ])
      end
    end

    context "#new_entries" do
      it "contains all de people" do
        expect(map_people_keys(scope.new_entries(:de).pluck(:id))).to match_array([
          :mitglied_and_abonnent,
          :new_entry,
          :new_entry_with_old_membership,
          :new_entry_abonnent_with_old_abo,
          :new_entry_mitglied_de_and_abonnent_fr
        ])
      end

      it "contains all fr people" do
        expect(map_people_keys(scope.new_entries(:fr).pluck(:id))).to match_array([
          :new_entry_fr,
          :new_entry_abonnent_fr,
          :abonnent_de_and_fr,
          :old_mitglied_new_abonnent_fr
        ])
      end

      it "contains no it people" do
        expect(map_people_keys(scope.new_entries(:it).pluck(:id))).to match_array([])
      end
    end
  end
end
