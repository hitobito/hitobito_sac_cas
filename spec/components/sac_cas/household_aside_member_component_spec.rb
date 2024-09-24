# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe HouseholdAsideMemberComponent, type: :component do
  let(:familienmitglied) { people(:familienmitglied) }
  let(:familienmitglied2) { people(:familienmitglied2) }
  let(:familienmitglied_kind) { people(:familienmitglied_kind) }

  subject(:component) { described_class.new(person: familienmitglied) }

  it "renders a person in the household with link" do
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector('a[data-turbo-frame="_top"][href="/de/people/600002"]', text: "Tenzing Norgay")
    expect(rendered_component).to have_selector("span", text: "(25)")
    expect(rendered_component).to have_text "Tenzing Norgay"
  end

  it "renders a person in the household without link" do
    stub_can(:show, false)
    stub_can(:set_sac_family_main_person, false)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector("strong", text: "Frieda Norgay")
    expect(rendered_component).to have_selector("span", text: "(25)")
    expect(rendered_component).to have_text("Frieda Norgay (25)")
  end

  it "renders all people in the household with ages" do
    stub_can(:show, false)
    stub_can(:set_sac_family_main_person, false)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_text("Tenzing Norgay (25)")
    expect(rendered_component).to have_text("Frieda Norgay (25)")
    expect(rendered_component).to have_text("Nima Norgay (10)")
  end

  it "renders people with main person link" do
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector("td", text: "Tenzing Norgay") do |a|
      expect(a.ancestor("tr")).to have_selector('span[title="Familienrechnungsempfänger"]')
    end
    expect(rendered_component).to have_selector("td a", text: "Frieda Norgay") do |a|
      expect(a.ancestor("tr")).to have_selector('a[title="Zum Familienrechnungsempfänger machen"]')
    end

    expect(rendered_component).to have_selector("td a", text: "Nima Norgay") do |a|
      expect(a.ancestor("tr")).not_to have_selector('span[title="Familienrechnungsempfänger"]')
      expect(a.ancestor("tr")).not_to have_selector('a[title="Zum Familienrechnungsempfänger machen"]')
    end
  end

  it "renders correct icon for active family member" do
    familienmitglied2.destroy!
    familienmitglied_kind.destroy!
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_css('span.text-primary[title="Familienrechnungsempfänger"]')
  end

  it "renders correct icon for possible family member" do
    familienmitglied2.destroy!
    familienmitglied_kind.destroy!
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    familienmitglied.update!(sac_family_main_person: false)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_css('a.text-muted[title="Zum Familienrechnungsempfänger machen"]')
  end

  it "renders correct icon for family member without email set" do
    familienmitglied2.destroy!
    familienmitglied_kind.destroy!
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    familienmitglied.update!(email: nil, sac_family_main_person: false)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_css('span.text-muted[title="Die Person hat keine E-Mail Adresse und kann daher nicht zum Familienrechnungsempfänger gemacht werden."]')
  end

  context "neunanmeldung" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }

    before do
      roles(:familienmitglied).destroy!
      roles(:familienmitglied2).destroy!
      r1 = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: familienmitglied, group: group)
      r2 = Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: familienmitglied2, group: group)
      key = Sequence.increment!(SacCas::Person::Household::HOUSEHOLD_KEY_SEQUENCE)
      Person.where(id: [familienmitglied.id, familienmitglied2.id]).update_all(household_key: key)
      familienmitglied.update!(sac_family_main_person: true)
      Role.where(id: [r1.id, r2.id]).update_all(beitragskategorie: :family)
      familienmitglied.reload
    end

    it "renders people with main person link for neuanmeldung" do
      stub_can(:show, true)
      stub_can(:set_sac_family_main_person, true)
      expect(familienmitglied.household).to have(2).members
      rendered_component = render_inline(component)
      expect(rendered_component).to have_selector("td", text: "Tenzing Norgay") do |a|
        expect(a.ancestor("tr")).to have_selector('span[title="Familienrechnungsempfänger"]')
      end
      expect(rendered_component).to have_selector("td a", text: "Frieda Norgay") do |a|
        expect(a.ancestor("tr")).to have_selector('a[title="Zum Familienrechnungsempfänger machen"]')
      end
    end
  end

  private

  def stub_can(permission, result)
    allow(component).to receive(:can?).with(permission, anything).and_return(result)
  end
end
