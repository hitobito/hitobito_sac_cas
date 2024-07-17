# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

RSpec.describe "people#show", type: :request do
  let(:token) { service_tokens(:permitted_root_layer_token).token }
  let(:person) { people(:admin) }

  subject(:make_request) { jsonapi_get "/api/people/#{person.id}" }

  before do
    person.update!(sac_remark_national_office: "Remark", sac_remark_section_1: "Remark")
    sign_in(person)
  end

  context "as employee" do
    it "can read national office remark but not section remarks" do
      make_request
      expect(d.sac_remark_national_office).to eq("Remark")
      expect(d.sac_remark_section_1).to be_blank
    end
  end

  context "as section functionary" do
    before do
      person.roles.destroy_all
      person.roles.create!(
        group: groups(:matterhorn_funktionaere),
        type: Group::SektionsFunktionaere::Administration.sti_name
      )
    end

    it "can read section remarks but not national office remark" do
      make_request
      expect(d.sac_remark_national_office).to be_blank
      expect(d.sac_remark_section_1).to eq("Remark")
    end
  end
end
