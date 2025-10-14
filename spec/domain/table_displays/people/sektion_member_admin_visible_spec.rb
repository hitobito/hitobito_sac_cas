# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::SektionMemberAdminVisible, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:mitglied) { people(:mitglied) }
  let(:current_user) { people(:admin) }
  let(:ability) { Ability.new(current_user) }
  let(:table) { StandardTableBuilder.new([mitglied.decorate], self) }
  let(:sektion_mitglieder) { groups(:bluemlisalp_mitglieder) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(sektion_mitglieder)
    roles(:mitglied).update!(end_on: Date.new(2025, 3, 10))
  end

  [[Person, [:roles_with_ended_readable, {roles_unscoped: :group}]],
    [Event::Participation,
      [:roles_with_ended_readable,
        {person: {roles_unscoped: :group}}]]].each do |model_class, expected_includes|
    context "table display on #{model_class}" do
      subject(:column) {
        TableDisplays::People::TerminateOnColumn.new(ability, model_class: model_class)
      }

      context "as admin" do
        it "shows value" do
          expect(column.value_for(mitglied, :terminated_on)).to eq "10.03.2025"
        end
      end

      context "in section" do
        context "with schreibrecht" do
          let(:current_user) {
            Fabricate(Group::SektionsMitglieder::Schreibrecht.sti_name,
              group: sektion_mitglieder).person
          }

          it "shows value" do
            expect(column.value_for(mitglied, :terminated_on)).to eq "10.03.2025"
          end
        end

        context "with mitgliederverwaltung" do
          let(:current_user) {
            Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name,
              group: groups(:bluemlisalp_funktionaere)).person
          }

          it "shows value" do
            expect(column.value_for(mitglied, :terminated_on)).to eq "10.03.2025"
          end
        end
      end

      context "from outside of sektion" do
        let(:current_user) {
          Fabricate(Group::SektionsMitglieder::Schreibrecht.sti_name,
            group: groups(:matterhorn_mitglieder)).person
        }

        it "shows value because we have show_full via zusatzsektion " do
          expect(column.value_for(mitglied, :terminated_on)).to eq "10.03.2025"
        end

        it "hides value when no zusatzsektion exists for that sektion" do
          roles(:mitglied_zweitsektion).destroy
          expect(column.value_for(mitglied, :terminated_on)).to eq "fehlende Berechtigung"
        end
      end

      context "without ability" do
        let(:ability) { Ability.new(people(:abonnent)) }

        it "hides value" do
          expect(column.value_for(mitglied, :terminated_on)).to eq "fehlende Berechtigung"
        end
      end

      it "only includes needed associations" do
        expect(column.required_model_includes(:terminated_on)).to eq expected_includes
      end

      describe "columns including or excluding" do
        [
          "beitrittsdatum",
          "birthday",
          "company",
          "company_name",
          "country",
          "data_quality",
          "email",
          "gender",
          "id",
          "j_s_number",
          "language",
          "membership_years",
          "nationality_j_s",
          "sac_remark_national_office",
          "sac_remark_section_1",
          "sac_remark_section_2",
          "sac_remark_section_3",
          "sac_remark_section_4",
          "sac_remark_section_5",
          "self_registration_reason",
          "terminate_on",
          "termination_reason",
          "wiedereintritt"
        ].each do |column|
          it "column #{column} includes #{described_class}" do
            column = TableDisplay.table_display_columns["Person"][column]
            expect(column.ancestors).to include(described_class)
          end
        end

        [
          "address_valid",
          "antrag_fuer",
          "antragsdatum",
          "beitragskategorie",
          "confirmed_at",
          "duplicate_exists",
          "layer_group_label",
          "login_status",
          "primary_group_id"
        ].each do |column|
          it "column #{column} excludes #{described_class}" do
            column = TableDisplay.table_display_columns["Person"][column]
            expect(column.ancestors).not_to include(described_class)
          end
        end
      end
    end
  end

  describe TableDisplays::PolymorphicShowFullColumn do
    let(:column) { described_class.new(ability, model_class:) }
    let(:participation) { Fabricate(:event_participation) }

    context "Event::Participation" do
      let(:model_class) { Event::Participation }

      context "with permission" do
        let(:ability) { Ability.new(people(:admin)) }

        it "returns values as permission check succeeds" do
          expect(column.value_for(participation,
            :invoice_state)).to eq [participation, :invoice_state]
        end
      end

      context "without permission" do
        let(:ability) { Ability.new(people(:abonnent)) }

        it "hides value" do
          participation = Fabricate(:event_participation, invoice_state: :draft)
          expect(column.value_for(participation, :invoice_state)).to eq "fehlende Berechtigung"
        end
      end
    end
  end
end
