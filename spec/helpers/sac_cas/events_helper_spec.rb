require "spec_helper"

describe EventsHelper do
  include FormatHelper

  let(:kind_category) { Fabricate.build(:event_kind_category) }
  let(:kind) {
    Fabricate.build(:event_kind, application_conditions: "kind conditions",
      kind_category: kind_category)
  }
  let(:event) { Fabricate.build(:course, kind: kind, application_conditions: "event conditions") }

  describe "#format_event_application_conditions" do
    it "does not render kind application conditions" do
      text = format_event_application_conditions(event)
      expect(text).to eq "event conditions"
    end

    it "does sill auto link" do
      event.application_conditions = "see www.hitobito.ch"
      text = format_event_application_conditions(event)
      expect(text).to eq 'see <a target="_blank" href="http://www.hitobito.ch">www.hitobito.ch</a>'
    end
  end

  describe "#price_category_label" do
    it "returns usual price labels for regular course" do
      expect(price_category_label(event, :price_member)).to eq "Mitgliederpreis"
      expect(price_category_label(event, :price_regular)).to eq "Normalpreis"
      expect(price_category_label(event, :price_subsidized)).to eq "Subventionierter Preis"
      expect(price_category_label(event, :price_special)).to eq "Spezialpreis"
    end

    it "returns j_s price labels for j_s course" do
      kind_category.j_s_course = true

      expect(price_category_label(event, :price_member)).to eq "J&S P-Mitgliederpreis"
      expect(price_category_label(event, :price_regular)).to eq "J&S P-Normalpreis"
      expect(price_category_label(event, :price_subsidized)).to eq "J&S A-Mitgliederpreis"
      expect(price_category_label(event, :price_special)).to eq "J&S A-Normalpreis"
    end
  end
end
