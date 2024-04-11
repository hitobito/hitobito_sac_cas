#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'shared/_course_signup_aside.html.haml' do
  include FormatHelper

  let(:dom) { render; Capybara::Node::Simple.new(@rendered)  }

  context 'summary' do
    it 'has static content' do
      expect(dom).to have_css 'h2.card-title', text: 'Zusammenfassung'
      expect(dom).to have_css '.card-text > table'
    end
  end

  context 'contact' do
    it 'has static content' do
      expect(dom).to have_css 'h2.card-title', text: 'Fragen zur Anmeldung'
      expect(dom).to have_css 'i', count: 3
    end
  end
end
