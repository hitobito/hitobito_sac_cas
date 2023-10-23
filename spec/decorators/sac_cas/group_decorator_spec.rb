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
    def render(person, group)
      html = GroupDecorator.new(group).primary_group_toggle_link(person, group)
      Capybara::Node::Simple.new(html) if html.present?
    end

    it 'builds link Hauptsektion setzen' do
      expect(render(mitglied, mitglieder)).to have_link 'Hauptsektion setzen'
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
end
