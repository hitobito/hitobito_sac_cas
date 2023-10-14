# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::MembershipController, type: :controller do

  let(:member) do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:be_mitglieder)).person
  end
  let(:funktionaer) do
    Fabricate(Group::SektionsFunktionaere::Verwaltung.sti_name.to_sym,
              group: groups(:be_funktionaere)).person
  end
  context 'GET show' do
    it 'is possible to download own membership pass' do
      sign_in(member)

      get :show, params: { id: member.id, format: 'pdf' }

      expect(response.status).to eq(200)
    end

    it 'is possible to download membership pass for writable person' do
      sign_in(funktionaer)

      get :show, params: { id: member.id, format: 'pdf' }

      expect(response.status).to eq(200)
    end

    it 'is not possible to download membership pass without access to person' do
      sign_in(member)

      expect do
        get :show, params: { id: funktionaer.id, format: 'pdf' }
      end.to raise_error(CanCan::AccessDenied)
    end

    context 'non member' do

      let(:non_member) do
        neu = Fabricate(Group::SektionsNeuanmeldungenNv.sti_name.to_sym, name: 'Neuanmeldungen', parent: groups(:be))
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym, group: neu).person
      end

      it 'is not possible to download membership pass' do
        sign_in(funktionaer)

        expect do
          get :show, params: { id: non_member.id, format: 'pdf' }
        end.to raise_error(ActionController::RoutingError, 'Not Found')
      end
    end

  end

end
