# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/tours/reports", js: true do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }

  before do
    event.update_column(:state, "ready")
    sign_in(user)
  end

  def visit_report
    visit edit_group_event_report_path(group, event)
  end

  describe "status changes" do
    let!(:recipient) { people(:mitglied) }

    before { create_recipient_role(recipient) }

    def create_recipient_role(person)
      Fabricate(Group::SektionsTourenUndKurse::Tourenchef.name.to_sym,
        group: groups(:bluemlisalp_touren_und_kurse),
        person:,
        start_on: 1.year.ago,
        end_on: 1.year.from_now)
    end

    context "draft status" do
      before { visit_report }

      it "shows forward option, but no reject option" do
        expect(page).to have_unchecked_field("Zur Freigabe einreichen an")
        expect(page).not_to have_unchecked_field("Ablehnen")
      end

      it "hides recipient dropdown until forwarding is chosen" do
        expect(page).not_to have_select("E-Mail Empfänger/-in")

        choose "Zur Freigabe einreichen an"

        expect(page).to have_select("E-Mail Empfänger/-in")
      end

      it "shows validation error and marks field red when forwarding without recipient" do
        choose "Zur Freigabe einreichen an"
        click_button "Speichern"

        expect(page).to have_selector("#error_explanation", text: "E-Mail Empfänger/-in muss ausgefüllt werden")
        expect(page).to have_css("select.is-invalid")
      end

      it "successfully forwards report to review status" do
        choose "Zur Freigabe einreichen an"
        select recipient.full_name, from: "E-Mail Empfänger/-in"
        click_button "Speichern"

        expect(page).to have_current_path(group_event_path(group, event))
        expect(report.reload.status).to eq(:review)
        expect(report.reload.submitter).to eq(user)
      end
    end

    context "review status" do
      before do
        report.update_columns(submitted_at: 1.day.ago, submitter_id: recipient.id)
        visit_report
      end

      it "shows forward and reject options" do
        expect(page).to have_unchecked_field("Zur Auszahlung freigeben an")
        expect(page).to have_unchecked_field("Ablehnen")
      end

      it "hides recipient dropdown until forwarding is chosen" do
        expect(page).not_to have_select("E-Mail Empfänger/-in")

        choose "Zur Auszahlung freigeben an"

        expect(page).to have_select("E-Mail Empfänger/-in")
      end

      it "shows recipient dropdown when rejecting" do
        expect(page).not_to have_select("E-Mail Empfänger/-in")

        choose "Ablehnen"

        expect(page).to have_select("E-Mail Empfänger/-in")
      end

      it "shows validation error and marks field red when forwarding without recipient" do
        choose "Zur Auszahlung freigeben an"
        click_button "Speichern"

        expect(page).to have_selector("#error_explanation", text: "E-Mail Empfänger/-in muss ausgefüllt werden")
        expect(page).to have_css("select.is-invalid")
      end

      it "successfully forwards report to approved status" do
        choose "Zur Auszahlung freigeben an"
        select recipient.full_name, from: "E-Mail Empfänger/-in"
        click_button "Speichern"

        expect(page).to have_current_path(group_event_path(group, event))
        expect(report.reload.status).to eq(:approved)
        expect(report.reload.approver).to eq(user)
      end

      it "successfully rejects report back to draft status" do
        choose "Ablehnen"
        click_button "Speichern"

        expect(page).to have_current_path(group_event_path(group, event))
        expect(report.reload.status).to eq(:draft)
      end
    end

    context "approved status" do
      before do
        report.update_columns(
          submitted_at: 2.days.ago, submitter_id: recipient.id,
          approved_at: 1.day.ago, approver_id: recipient.id
        )
        visit_report
      end

      it "shows forward and reject options but no recipient dropdown" do
        expect(page).to have_unchecked_field("Auszahlung erfasst")
        expect(page).to have_unchecked_field("Ablehnen")
        expect(page).not_to have_select("E-Mail Empfänger/-in")
      end

      it "successfully records payout and transitions to closed status" do
        choose "Auszahlung erfasst"
        click_button "Speichern"

        expect(page).to have_current_path(group_event_path(group, event))
        expect(report.reload.status).to eq(:closed)
        expect(report.reload.payer).to eq(user)
      end

      it "successfully rejects report back to review status" do
        choose "Ablehnen"
        click_button "Speichern"

        expect(page).to have_current_path(group_event_path(group, event))
        expect(report.reload.status).to eq(:review)
      end
    end
  end

  describe "cost tab" do
    let(:revenue) { event_costs(:participation_fee) }
    let(:expense) { event_costs(:transport) }
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
      visit_report
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
        table_total = find("#expenses_total")

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

      it "does not add duplicate dom rows when clicking add tour prices twice" do
        create_participation(price_category: "price_member", price: 10)

        click_button "Tourengebühren hinzufügen"

        expect(all(".fields", visible: :all).size).to eq 3

        click_button "Tourengebühren hinzufügen"

        expect(all(".fields", visible: :all).size).to eq 3
      end

      it "assigns unique field names to rows added in the same click" do
        create_participation(price_category: "price_member", price: 10)
        create_participation(price_category: "price_special", price: 40)

        click_button "Tourengebühren hinzufügen"

        field_names = all(".fields[data-new-record] input[name*='[description]']").pluck(:name)
        expect(field_names).to match_array(field_names.uniq)
      end

      it "shows error and marks field red when description is blank" do
        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("count", "4")
            set_field("amount", "80")
          end
        end

        click_button "Speichern"

        expect(page).to have_selector("#error_explanation", text: "Bezeichnung muss ausgefüllt werden")

        click_link "Kostenübersicht"

        expect(page).to have_css("input.is-invalid")
      end

      it "shows error and marks field red when count is blank" do
        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("description", "Kursgebühr")
            set_field("amount", "80")
          end
        end

        click_button "Speichern"

        expect(page).to have_selector("#error_explanation", text: "Anzahl muss ausgefüllt werden")

        click_link "Kostenübersicht"

        expect(page).to have_css("input.is-invalid")
      end

      it "shows error and marks field red when amount is blank" do
        within("fieldset", text: "Einnahmen") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("description", "Kursgebühr")
            set_field("count", "4")
          end
        end

        click_button "Speichern"

        expect(page).to have_selector("#error_explanation", text: "Betrag muss ausgefüllt werden")

        click_link "Kostenübersicht"

        expect(page).to have_css("input.is-invalid")
      end
    end

    describe "expenses" do
      it "can add an expense" do
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

      it "shows error and marks field red when a required field is blank" do
        within("fieldset", text: "Ausgaben") do
          click_link "Eintrag hinzufügen"
          within(".fields[data-new-record]") do
            set_field("count", "2")
            set_field("amount", "120")
          end
        end

        click_button "Speichern"

        expect(page).to have_selector("#error_explanation", text: "Bezeichnung muss ausgefüllt werden")

        click_link "Kostenübersicht"

        expect(page).to have_css("input.is-invalid")
      end

      it "updates the row total and section total when count and amount change" do
        table_total = find("#expenses_total")

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
        table_total = find("#expenses_total")

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
