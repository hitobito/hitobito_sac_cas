# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/tours/reports", js: true do
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:revenue) { event_costs(:participation_fee) }
  let(:expenditure) { event_costs(:transport) }
  let(:receipt) { event_cost_receipts(:tankstelle) }

  def create_participation(price_category:, price:)
    Fabricate(:event_participation, event: event, price_category: price_category, price: price).tap do
      Fabricate(Event::Role::Participant.sti_name, participation: _1)
    end
  end

  def set_field(name, value)
    find("input[name*='[#{name}]']").set(value)
    page.send_keys(:tab)
  end

  before do
    event.update_column(:state, "ready")
    sign_in(people(:admin))
    visit edit_group_event_report_path(group, event)
  end

  describe "cost tab" do
    before do
      click_link "Kostenübersicht"
    end

    describe "revenues" do
      it "can add a revenue" do
        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("description", "Kursgebühr")
            set_field("count", "4")
            set_field("amount", "80")
          end
        end

        click_button "Speichern"
        expect(page).to have_text "Tourenrapport wurde erfolgreich aktualisiert"

        expect(report.reload.costs.where(income: true).count).to eq(2)
      end

      it "updates the row total and section total when count and amount change" do
        table_total = find("#revenues_total")

        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(all(".fields[data-new-record]").last) do
            set_field("description", "Kursgebühr")
            set_field("count", "4")
            set_field("amount", "80")
            expect(page).to have_text("320.00")
            expect(table_total).to have_text("820.00")

            set_field("count", "2")
            expect(page).to have_text("160.00")
            expect(table_total).to have_text("660.00")

            set_field("amount", "40")
            expect(page).to have_text("80.00")
            expect(table_total).to have_text("580.00")
          end
        end

        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(all(".fields[data-new-record]").last) do
            set_field("description", "Kursgebühr")
            set_field("count", "2")
            set_field("amount", "1000")
            expect(page).to have_text("2000.00")
            expect(table_total).to have_text("2580.00")
          end
        end
      end

      it "updates the section total when a row is removed" do
        table_total = find("#expenditures_total")

        within("fieldset", text: "Einnahmen") do
          click_link "Entfernen"
          expect(page).to have_text("0.00")
          expect(table_total).to have_text("0.00")
        end
      end

      it "add tour prices buttons adds every combination as a row" do
        table_total = find("#revenues_total")
        create_participation(price_category: "price_member", price: 10)
        create_participation(price_category: "price_member", price: 10)
        create_participation(price_category: "price_special", price: 40)

        click_button "Tourengebühren hinzufügen"

        within("fieldset", text: "Einnahmen") do
          member_row = all(".fields[data-new-record]").find {
            _1.find("input[name*='[description]']").value == "Kosten SAC-Mitglied (extern)"
          }
          special_row = all(".fields[data-new-record]").find {
            _1.find("input[name*='[description]']").value == "Kosten SAC Sektionsmitglied"
          }

          within(member_row) { expect(page).to have_text("20.00") }
          within(special_row) { expect(page).to have_text("40.00") }
        end

        expect(table_total).to have_text("560.00")
      end

      it "overrides existing rows if description matches tour price category label" do
        table_total = find("#revenues_total")
        create_participation(price_category: "price_member", price: 10)

        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(all(".fields[data-new-record]").last) do
            set_field("description", "Kosten SAC-Mitglied (extern)")
            set_field("count", "4")
            set_field("amount", "80")
          end
        end

        click_button "Tourengebühren hinzufügen"

        expect(page).to have_field(name: /\[description\]/, with: "Kosten SAC-Mitglied (extern)")
        expect(page).to have_text("10.00")
        expect(table_total).to have_text("510.00")
      end

      it "removes existing row if description matches and count returning count is zero" do
        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(all(".fields[data-new-record]").last) do
            set_field("description", "Kosten SAC-Mitglied (extern)")
          end
        end

        event.participations.destroy_all

        click_button "Tourengebühren hinzufügen"

        expect(page).not_to have_field(name: /\[description\]/, with: "Kosten SAC-Mitglied (extern)")
      end
    end

    describe "expenditures" do
      it "can add an expenditure" do
        within("fieldset", text: "Ausgaben") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("description", "Ausrüstung")
            set_field("count", "2")
            set_field("amount", "120")
          end
        end

        click_button "Speichern"
        expect(page).to have_text "Tourenrapport wurde erfolgreich aktualisiert"

        expect(report.reload.costs.where(income: false).count).to eq(2)
      end

      it "updates the row total and section total when count and amount change" do
        table_total = find("#expenditures_total")

        within("fieldset", text: "Ausgaben") do
          click_link "Eintrag hinzufügen"
          within(all(".fields[data-new-record]").last) do
            set_field("description", "Kursgebühr")
            set_field("count", "4")
            set_field("amount", "80")
            expect(page).to have_text("320.00")
            expect(table_total).to have_text("620.00")

            set_field("count", "2")
            expect(page).to have_text("160.00")
            expect(table_total).to have_text("460.00")

            set_field("amount", "40")
            expect(page).to have_text("80.00")
            expect(table_total).to have_text("380.00")
          end
        end

        within("fieldset", text: "Ausgaben") do
          click_link "Eintrag hinzufügen"
          within(all(".fields[data-new-record]").last) do
            set_field("description", "Kursgebühr")
            set_field("count", "2")
            set_field("amount", "1000")
            expect(page).to have_text("2000.00")
            expect(table_total).to have_text("2380.00")
          end
        end
      end

      it "updates the section total when a row is removed" do
        table_total = find("#expenditures_total")

        within("fieldset", text: "Ausgaben") do
          click_link "Entfernen"
          expect(page).to have_text("0.00")
          expect(table_total).to have_text("0.00")
        end
      end
    end

    describe "receipts" do
      it "can add a receipt" do
        within("fieldset", text: "Belege") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("description", "Tankquittung")
            attach_file find("input[name*='[file]']")[:id], file_fixture("icon.png")
          end
        end

        click_button "Speichern"
        expect(page).to have_text "Tourenrapport wurde erfolgreich aktualisiert"

        expect(report.reload.cost_receipts.count).to eq(2)
      end
    end
  end
end
