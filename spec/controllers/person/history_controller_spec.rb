# frozen_string_literal: true

#  Copyright (c) 2025-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::HistoryController do
  render_views

  let(:body) { Capybara::Node::Simple.new(response.body) }
  let(:user) { people(:admin) }
  let(:participation) { event_participations(:top_mitglied) }

  before { sign_in(user) }

  context "GET#index" do
    it "renders actual days for participation" do
      participation.event.update!(training_days: 4)
      participation.update!(actual_days: 2.5)

      get :index,
        params: {group_id: participation.person.groups.first.id, id: participation.participant_id}

      quali = body.find("tr#event_participation_#{participation.id} td:last-child")
      expect(quali.text.strip).to eq("2.5 Ausbildungstage")
    end

    context "external trainings section" do
      let(:mitglied) { people(:mitglied) }

      def get_index
        get :index, params: {group_id: groups(:bluemlisalp_mitglieder).id, id: mitglied.id}
      end

      it "is not counted without entries" do
        get_index

        expect(controller.send(:history_section_sizes)).not_to include(0)
        expect(body).to have_css "#external_trainings .collapse.show"
      end

      it "collapses all sections with many external trainings" do
        11.times { Fabricate(:external_training_skip_issue_qualifications, person: mitglied) }
        get_index

        expect(controller.send(:history_section_sizes).last).to eq 11
        expect(body).to have_css "#external_trainings .collapse:not(.show)"
        expect(body).to have_css "#roles .collapse:not(.show)"
      end
    end
  end
end
