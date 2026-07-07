# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/activities/_form.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(entry: activity, model_class: Event::Activity, path_args: [activity])
  end

  context "new main activity" do
    let(:activity) { Event::Activity.new }

    it "renders color and parent fields" do
      expect(dom).to have_field "Farbe", visible: true
      expect(dom).to have_select "Übergeordnete Aktivität", visible: true
    end

    it "does not render technical requirement field" do
      expect(dom).to have_select "Technische Anforderung", visible: false
    end
  end

  context "edit main activity" do
    let(:activity) { event_activities(:klettern) }

    it "renders color and technical requirment fields" do
      expect(dom).to have_field "Farbe", visible: true
    end

    it "does not render parent and technical requirment fields" do
      expect(dom).to have_no_select "Übergeordnete Aktivität"
      expect(dom).to have_select "Technische Anforderung", visible: false
    end
  end

  context "edit child activity" do
    let(:activity) { event_activities(:felsklettern) }

    it "does render technical requirement field" do
      expect(dom).to have_select "Technische Anforderung", visible: true
    end

    it "does not render color and parent fields" do
      expect(dom).to have_field "Farbe", visible: false
      expect(dom).to have_no_select "Übergeordnete Aktivität"
    end
  end
end
