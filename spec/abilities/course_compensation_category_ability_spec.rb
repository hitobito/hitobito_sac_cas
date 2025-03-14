# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe CourseCompensationCategoryAbility do
  let(:entry) { Fabricate(:course_compensation_category) }
  let(:ability) { Ability.new(role.person.reload) }

  context "with admin permission" do
    let(:role) { roles(:admin) }

    it "may index CourseCompensationCategory records" do
      expect(ability).to be_able_to(:index, CourseCompensationCategory)
    end

    it "may manage CourseCompensationCategory records" do
      expect(ability).to be_able_to(:manage, entry)
    end
  end

  context "without admin permission" do
    let(:role) { roles(:tourenchef_bluemlisalp_ortsgruppe_ausserberg) }

    it "may not index CourseCompensationCategory records" do
      expect(ability).not_to be_able_to(:index, CourseCompensationCategory)
    end

    it "may not show CourseCompensationCategory records" do
      expect(ability).not_to be_able_to(:show, entry)
    end

    %w[create update destroy].each do |action|
      it "may not #{action} CourseCompensationCategory records" do
        expect(ability).not_to be_able_to(action.to_sym, entry)
      end
    end
  end
end
