# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SacCas::GroupDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers
  let(:context) { double('context') }

  let(:sektion) { groups(:bluemlisalp) }
  let(:mitglied) { people(:mitglied) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }

  describe '#primary_group_toggle_link' do
    before do
      c = ApplicationController.new
      c.request = ActionDispatch::TestRequest.new({})
      allow(c).to receive(:current_person) { current_person }
      Draper::ViewContext.current = c.view_context
    end

    def render(person, group)
      html = GroupDecorator.new(group).primary_group_toggle_link(person, group)
      Capybara::Node::Simple.new(html) if html.present?
    end

    context 'with permission change primary_group' do
      let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
      let(:current_person) { people(:admin) }

      it 'builds Stammsektion icon' do
        node = render(mitglied, mitglieder)
        expect(node).to have_css "i.fa.fa-star"
        expect(node).to have_xpath "//i[@filled='true']"
        expect(node).to have_xpath "//i[@title='Stammsektion']"
      end

      it 'builds link Hauptgruppe setzen for other type for non preferred primary group' do
        expect(sektion).not_to be_preferred_primary
        mitglied.update_columns(primary_group_id: sektion.id)
        expect(render(mitglied, sektion)).to have_link 'Hauptgruppe setzen'
      end

      it 'is blank for other type for for preferred primary group' do
        expect(mitglied.primary_group).to be_preferred_primary
        expect(render(mitglied, sektion)).to be_blank
      end
    end

    context 'for herself' do
      let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
      let(:current_person) { mitglied }

      it 'builds Stammsektion icon for primary group' do
        node = render(mitglied, mitglieder)
        expect(node).to have_css "i.fa.fa-star"
        expect(node).to have_xpath "//i[@filled='true']"
        expect(node).to have_xpath "//i[@title='Stammsektion']"
      end

      it 'is blank for other preferred role other role' do
        other = Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023).children
          .find_by(type: Group::SektionsMitglieder)
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other, person: mitglied, beitragskategorie: :einzel)
        expect(other).to be_preferred_primary
        expect(render(mitglied, other)).to be_blank
      end

      it 'is blank for any other role' do
        expect(sektion).not_to be_preferred_primary
        expect(render(mitglied, sektion)).to be_blank
      end
    end
  end
end
