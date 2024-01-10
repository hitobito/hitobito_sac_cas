# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe TableDisplays::ResolvingColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied)  }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self)}
  let(:parent) { Group.new(id: 1) }

  subject(:node) { Capybara::Node::Simple.new(table.to_html) }

  shared_examples 'table display' do |column:, header:, value: '', permission:|
    subject(:display) { described_class.new(ability, table: table, model_class: Person)}
    subject(:node) { Capybara::Node::Simple.new(table.to_html) }

    it "requires #{permission} as permission" do
      expect(display.required_permission(column)).to eq permission
    end

    it "renders #{header} as header" do
      display.render(column)
      expect(node).to have_css 'th', text: header
    end

    it "renders #{value} as value" do
      display.render(column)
      expect(node).to have_css 'td', text: value
    end
  end


  it_behaves_like 'table display', {
    column: :beitragskategorie,
    header: 'Beitragskategorie',
    value: 'Einzel',
    permission: :show_full
  }

  it_behaves_like 'table display', {
    column: :membership_years,
    header: 'Anzahl Mitglieder-Jahre',
    value: '3',
    permission: :show
  } do
    let(:person) { people(:admin).tap { |p| allow(p).to receive(:membership_years).and_return(3) } }
  end

end
