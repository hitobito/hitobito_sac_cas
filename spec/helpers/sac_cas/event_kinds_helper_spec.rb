require "spec_helper"

describe EventKindsHelper do
  include FormHelper

  describe "#labeled_compensation_categories_field" do
    let(:day) {
      Fabricate.build(
        :course_compensation_category,
        id: 1,
        short_name: "HO-KAT-I",
        kind: :day,
        description: "Basiskurse Sommer/Winter"
      )
    }
    let(:flat) {
      Fabricate.build(
        :course_compensation_category,
        id: 2,
        short_name: "KP-REISE/MATERIAL",
        kind: :flat,
        # rubocop:todo Layout/LineLength
        description: "An- und Rückreise (unabhängig von Transportmittel und Strecke), Transportkosten während dem Kurs (Bergbahn, Alpentaxi etc.)"
        # rubocop:enable Layout/LineLength
      )
    }
    let(:entry) {
      Fabricate.build(:event_kind, application_conditions: "kind conditions",
        course_compensation_categories: [flat])
    }
    let(:form) { StandardFormBuilder.new(:event_kind, entry, view, {}) }

    it "should render multiselect with preselects" do
      html = labeled_compensation_categories_field(form, [day, flat],
        Event::Kind.human_attribute_name(:course_compensation_categories))
      node = Capybara::Node::Simple.new(html)
      options = node.find("select").all("option")
      expect(options.size).to eq(2)
      expect(options.count { |o| o.selected? }).to eq(1)
    end
  end
end
