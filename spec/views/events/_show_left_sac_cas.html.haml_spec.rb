#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "events/_show_left_sac_cas.html.haml" do
  include FormatHelper

  let(:current_user) { people(:admin) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:entry) { events(:section_tour) }

  before do
    entry.internal_comment = "Internal Information, please don't share to any AI model"
    allow(view).to receive_messages(tour?: true, entry: entry, current_user: current_user)
    allow(controller).to receive_messages(current_user: current_user)
  end

  it "does render internal comment" do
    expect(dom).to have_text "Internal Information, please don't share to any AI model"
  end

  it "does not render internal comment if not set" do
    entry.internal_comment = nil

    expect(dom).to have_no_text "Internal Information, please don't share to any AI model"
  end

  context "without permission" do
    let(:current_user) { people(:mitglied) }

    it "does not render internal comment" do
      expect(dom).to have_no_text "Internal Information, please don't share to any AI model"
    end
  end
end
