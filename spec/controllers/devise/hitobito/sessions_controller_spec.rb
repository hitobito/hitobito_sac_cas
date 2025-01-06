#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Devise::Hitobito::SessionsController do
  let(:password) { "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9" }
  let(:person) { people(:mitglied) }

  context "#create" do
    before do
      person.update!(password: password)
      request.env["devise.mapping"] = Devise.mappings[:person]
    end

    it "displays flash message after login when data quality issues exist" do
      person.update_column(:birthday, nil)
      People::DataQualityChecker.new(person).check_data_quality
      post :create, params: {person: {login_identity: person.email, password: password}}
      expect(flash[:notice]).to eq "Das SAC Portal kann aktuell nicht vollständig verwendet werden da deine angegebenen Daten nicht vollständig sind. Bitte ergänze diese, um alle Funktionen verwenden zu können."
    end
  end
end
