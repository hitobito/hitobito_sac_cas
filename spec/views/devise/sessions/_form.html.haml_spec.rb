#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "devise/sessions/_form.html.haml" do
  subject(:dom) { Capybara::Node::Simple.new(raw(rendered)) }

  before do
    allow(view).to receive(:resource).and_return(Person.new)
  end

  it "does render custom helpful links" do
    render
    expect(dom).to have_text Group.root.to_s
    expect(dom).to have_text Group.root.address
  end
end
