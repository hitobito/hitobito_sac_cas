# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Subscriber::FilterController do

  before { sign_in(people(:admin)) }
  let(:mailing_list) { Fabricate(:mailing_list, group: groups(:root)) }

  context 'PATCH update' do
    let(:filters) do
      {
        language: { "allowed_values" => %w[de fr] },
        attributes: { "1699698452786" => {"constraint" => "greater", "key" => "years", "value" => "16" } }
      }
    end

    let(:params) do
      {
        group_id: mailing_list.group_id,
        mailing_list_id: mailing_list.id,
        filters: filters
      }
    end

    let(:ability_manage_all) do
      Class.new do
        include CanCan::Ability
        def user = nil
        def initialize
          can :manage, :all
        end
      end.new
    end

    let(:ability_cannot_update_filter_chain) do
      Class.new(ability_manage_all.class) do
        def initialize
          super
          cannot :update, MailingList, :filter_chain
        end
      end.new
    end

    before {  }

    it 'sets the filter values' do
      allow(controller).to receive(:current_ability).and_return(ability_manage_all)

      put :update, params: params

      expect(response).to redirect_to(group_mailing_list_subscriptions_path(group_id: mailing_list.group.id,
                                                                            id: mailing_list.id))

      filter_chain = mailing_list.reload.filter_chain
      expect(filter_chain[:language]).to be_a(Person::Filter::Language)
      expect(filter_chain[:language].args).to eq(filters[:language].deep_stringify_keys)
      expect(filter_chain[:language].allowed_values).to contain_exactly('de', 'fr')
      expect(filter_chain[:attributes]).to be_a(Person::Filter::Attributes)
      expect(filter_chain[:attributes].args).to eq(filters[:attributes].deep_stringify_keys)
    end

    it 'responds 403 if user has no permission to update filter_chain' do
      allow(controller).to receive(:current_ability).and_return(ability_cannot_update_filter_chain)

      expect { put :update, params: params }.
        to raise_error(CanCan::AccessDenied).
          and not_change { mailing_list.reload.filter_chain.to_hash }
    end
  end
end
