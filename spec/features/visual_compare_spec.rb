# frozen_string_literal: true
require "spec_helper"

describe "visual compare", js: true do
  let(:group) { groups(:bluemlisalp) }
  let(:tour) { events(:section_tour) }
  let(:out_dir) { "/tmp/claude-1000/-home-zumkehr-src-ruby-hitobito-hitobito/007fefe7-5280-4e1a-a097-b0913cf6b0e2/scratchpad/screenshots" }

  around { |example| travel_to(Time.zone.local(2026, 1, 1)) { example.run } }

  before do
    tour.update_columns(state: :published, globally_visible: true, display_booking_info: true)
  end

  it "screenshots the prototype" do
    visit "https://chrusu.github.io/Tourenportal-Prototype/"
    sleep 1
    page.save_screenshot("#{out_dir}/prototype_full.png")
  end

  it "screenshots the prototype with activities filter open" do
    visit "https://chrusu.github.io/Tourenportal-Prototype/"
    sleep 1
    click_button "Aktivitäten"
    sleep 0.5
    page.save_screenshot("#{out_dir}/prototype_activities.png")
  end

  it "screenshots our implementation" do
    visit agenda_index_path(group_id: group.id)
    sleep 0.5
    page.save_screenshot("#{out_dir}/ours_full.png")
  end

  it "screenshots our implementation with activities filter open" do
    visit agenda_index_path(group_id: group.id)
    click_button "Aktivitäten"
    sleep 0.3
    page.save_screenshot("#{out_dir}/ours_activities.png")
  end
end
