# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::SwitchStammsektionsController do
  include ActiveJob::TestHelper

  let(:current_user) { people(:admin) }
  let(:root) { groups(:root) }
  let(:person) { people(:mitglied) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:stammsektion_role) { person.sac_membership.stammsektion_role }

  def wizard_params(step: 0, kind: nil, **attrs)
    key = if /zusatzsektion/.match?(kind)
      "wizards_memberships_swap_stamm_zusatzsektion"
    else
      "wizards_memberships_switch_stammsektion"
    end

    {
      group_id: stammsektion_role.group_id,
      person_id: person.id,
      step: step,
      kind:
    }.compact_blank.merge(key => attrs)
  end

  before { sign_in(current_user) }

  context "single person" do
    it "response with 422 when flash message" do
      post :create, params: wizard_params(choose_sektion: {group_id: root.id})
      expect(response).to have_http_status(422)
    end

    it "switches stammsektion, sends email and sets flash" do
      roles(:mitglied_zweitsektion).destroy
      expect do
        post :create, params: wizard_params(step: 1, choose_sektion: {group_id: matterhorn.id})
      end.to have_enqueued_mail(Memberships::SwitchStammsektionMailer, :confirmation)
      expect(person.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(response).to redirect_to(person_path(person, format: :html))
      expect(flash[:notice]).to eq "Dein Sektionswechsel zu <i>SAC Matterhorn</i> wurde vorgenommen."
    end

    it "switches stammsektion with zusatzsektion without sending email" do
      expect do
        post :create, params: wizard_params(kind: :zusatzsektion, step: 1, choose_sektion: {group_id: matterhorn.id})
      end.not_to have_enqueued_mail
      expect(person.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(response).to redirect_to(person_path(person, format: :html))
      expect(flash[:notice]).to eq "Dein Sektionswechsel zu <i>SAC Matterhorn</i> wurde vorgenommen."
    end
  end

  context "family" do
    let(:person) { people(:familienmitglied) }
    let(:family_member) { people(:familienmitglied2) }

    it "makes switch for all family members" do
      roles(:familienmitglied_zweitsektion).destroy
      roles(:familienmitglied2_zweitsektion).destroy
      roles(:familienmitglied_kind_zweitsektion).destroy
      person.update_column(:data_quality, :ok)

      expect do
        post :create, params: wizard_params(step: 1, choose_sektion: {group_id: matterhorn.id})
      end.to have_enqueued_mail(Memberships::SwitchStammsektionMailer, :confirmation)
      expect(response).to redirect_to(person_path(person, format: :html))
      expect(flash[:notice]).to eq "Eure 3 Sektionswechsel zu <i>SAC Matterhorn</i> wurden vorgenommen."
      expect(person.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(family_member.sac_membership.stammsektion_role.layer_group).to eq matterhorn
    end

    it "makes switch for all family members without sending email" do
      person.update_column(:data_quality, :ok)

      expect do
        post :create, params: wizard_params(kind: :zusatzsektion, step: 1, choose_sektion: {group_id: matterhorn.id})
      end.not_to have_enqueued_mail(Memberships::SwitchStammsektionMailer, :confirmation)
      expect(response).to redirect_to(person_path(person, format: :html))
      expect(flash[:notice]).to eq "Eure 3 Sektionswechsel zu <i>SAC Matterhorn</i> wurden vorgenommen."
      expect(person.sac_membership.stammsektion_role.layer_group).to eq matterhorn
      expect(family_member.sac_membership.stammsektion_role.layer_group).to eq matterhorn
    end
  end
end
