#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FilterNavigation::Events do
  include LayoutHelper
  include FormatHelper
  include UtilityHelper
  include I18nHelper
  let(:current_user) { people(:admin) }
  let(:params) { ActionController::Parameters.new(group_id: group.id, controller: :events) }

  let(:filter) { Events::Filter::GroupList.new(group, current_user, params) }
  let(:dom) { Capybara::Node::Simple.new(subject.to_s) }
  subject { described_class.new(self, group, filter) }

  let(:group) { groups(:bluemlisalp) }

  it "has links for Events" do
    expect(dom).to have_link "Meine Anlässe als Hauptleitung"
    expect(dom).to have_link "Meine Anlässe als Hilfsleitung"
  end

  context "for course" do
    before { params[:type] = "Event::Course" }

    it "has links for Events" do
      expect(dom).to have_link "Meine Kurse als Hauptleitung"
      expect(dom).to have_link "Meine Kurse als Hilfsleitung"
    end
  end

  context "for tours" do
    before { params[:type] = "Event::Tour" }

    it "has links for Events" do
      expect(dom).to have_link "Meine Touren als Hauptleitung"
      expect(dom).to have_link "Meine Touren als Hilfsleitung"
    end
  end
end
