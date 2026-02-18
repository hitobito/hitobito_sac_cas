require "spec_helper"

describe EventsHelper do
  include UtilityHelper
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

  describe "#event_essentials_list" do
    let(:event) { events(:section_tour) }

    before do
      event.update!(state: :draft)
    end

    it "returns list of children with parent for disciplines" do
      event.disciplines = event_disciplines(:bergtour, :wanderweg, :felsklettern)

      html = format_event_disciplines(event)
      expect(html).to match(/<li><a .+?>Wandern<\/a> \(<a .+?>Wanderweg<\/a>, <a .+?>Bergtour<\/a>\)<\/li>/)
      expect(html).to match(/<li><a .+?>Klettern<\/a> \(<a .+?>Fels<\/a>\)<\/li>/)
    end

    it "returns list of parents without children for target groups" do
      event.target_groups = event_target_groups(:erwachsene, :senioren_b)

      html = format_event_target_groups(event)
      expect(html).to match(/<li><a .+?>Erwachsene<\/a><\/li>/)
      expect(html).to match(/<li><a .+?>Senioren<\/a> \(<a .+?>Senioren B<\/a>\)<\/li>/)
    end

    it "returns list with unwrapped children and custom separator for technical requirements" do
      event.technical_requirements = event_technical_requirements(:klettern_5a, :klettern_5b_plus, :skitouren_ws)
      event_technical_requirements(:skitouren_ws).update!(label: "<b>WS</b>")

      html = format_event_technical_requirements(event)
      expect(html).to match(/<li><a .+?>Französische Kletterskala<\/a>: 5a, 5b\+<\/li>/)
      expect(html).to match(/<li><a .+?>Skitourenskala<\/a>: &lt;b&gt;WS&lt;\/b&gt;<\/li>/)
    end

    it "returns comma separated list for traits" do
      event.traits = event_traits(:public_transport, :excursion, :work)
      event_traits(:public_transport).update!(description: "Oder mit dem Velo")

      html = format_event_traits(event)
      expect(html).to match(/<a .+?>Anreise mit ÖV<\/a>, Arbeitseinsatz, Exkursion/)
    end
  end
end
