# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe ChangelogController do
  before { sign_in(person) }

  context "GET #index" do
    context "as geschätsstelle" do
      let(:person) { people(:admin) }

      it "is authorized" do
        expect do
          get :index
        end.not_to raise_error
      end
    end

    context "as mitglied" do
      let(:person) { people(:mitglied) }

      it "is unauthorized" do
        expect do
          get :index
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
