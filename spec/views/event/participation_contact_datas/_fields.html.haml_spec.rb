#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participation_contact_datas/_fields.html.haml" do
  include FormatHelper

  let(:participation_contact_data) { Event::ParticipationContactData.new(events(:top_course), people(:mitglied)) }
  let(:form_builder) { StandardFormBuilder.new(:participation_contact_data, participation_contact_data, view, {}) }

  before do
    allow(form_builder).to receive(:fields_for).and_return([])
    allow(view).to receive_messages(f: form_builder, entry: participation_contact_data, phone_numbers: [])
  end

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  context "required fields" do
    [:email, :first_name, :last_name, :birthday, :address, :zip_code, :town, :country].each do |field|
      it "#{field} is rendered with required mark" do
        expect(dom).to have_css "label.required", text: participation_contact_data.class.human_attribute_name(field)
      end
    end
  end
end
