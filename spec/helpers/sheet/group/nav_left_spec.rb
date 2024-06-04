# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'Sheet::Group::NavLeft' do
  let(:group) { groups(:root) }
  let(:sheet) { Sheet::Group.new(self, nil, group) }
  let(:nav)   { Sheet::Group::NavLeft.new(sheet) }

  let(:request) { ActionController::TestRequest.create({}) }

  let(:html) { nav.render }
  subject(:dom) { Capybara::Node::Simple.new(html) }

  def can?(*_args)
    true
  end

  describe 'ordering of sections' do
    let(:links) { dom.all('li').map(&:text) }
    let(:sections) { links[links.index('Sektionen')+1..] }
    let(:bluemlisalp) { groups(:bluemlisalp) }
    let(:matterhorn) { groups(:matterhorn) }

    it 'orders sections by name' do
      expect(sections).to eq  ['SAC Blüemlisalp', 'SAC Matterhorn']
    end

    it 'ignores cas prefix' do
      matterhorn.update!(name: 'CAS Matterhorn')
      expect(sections).to eq ['SAC Blüemlisalp', 'CAS Matterhorn']
    end

    it 'ignores sac prefix' do
      bluemlisalp.update!(name: 'CAS Blüemlisalp')
      matterhorn.update!(name: 'SAC Altels')
      expect(sections).to eq ['SAC Altels', 'CAS Blüemlisalp']
    end
  end
end
