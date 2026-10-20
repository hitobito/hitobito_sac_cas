# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

[
  Event::ActivityResource,
  Event::TargetGroupResource,
  Event::TechnicalRequirementResource,
  Event::TraitResource
].each do |resource_class|
  describe resource_class, type: :resource do
    let(:person) { people(:admin) }

    before { allow(Graphiti.context[:object]).to receive(:current_scopes).and_return(["api"]) }

    it "includes parent" do
      params[:include] = "parent"
      params[:page] = {size: 100}
      render

      parent_ids = jsonapi_data.to_h do |entry|
        [entry.id, entry.relationships.dig(:parent, :data, :id)&.to_i]
      end
      expect(parent_ids.values.compact).to be_present
      expect(parent_ids).to eq(resource_class.model.where(id: parent_ids.keys).pluck(:id, :parent_id).to_h)
    end
  end
end
