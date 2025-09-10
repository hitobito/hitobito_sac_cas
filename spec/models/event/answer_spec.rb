# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Answer do
  let(:event) { events(:top_course) }
  let!(:question1) { Event::Question::Default.create(event:, question: "Ich bin Vegetarier", disclosure: "optional") }
  let!(:question2) { Event::Question::Default.create(event:, question: "Sonst noch was?", disclosure: "optional") }
  let!(:question3) { Event::Question::Default.create(event:, question: "GA oder Halbtax?", choices: "GA, Halbtax, nix", disclosure: "optional") }
  let(:participation) { event.participations.first }

  context ".list" do
    it "orders by questions and includes translations" do
      participation.init_answers
      ids = participation.answers.pluck(:id)

      expect_query_count do
        list = participation.answers.list.to_a
        expect(list.map { |a| a.question.question })
          .to eq(["GA oder Halbtax?", "Ich bin Vegetarier", "Sonst noch was?"])
        expect(list.map(&:id)).to match_array(ids)
      end.to eq(3)
    end
  end
end
