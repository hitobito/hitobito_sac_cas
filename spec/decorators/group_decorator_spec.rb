# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe GroupDecorator do
  before do
    # cannot use `draper_with_helpers` as it sets up TestRequest with empty env
    # which has no host, so we set it up manually
    c = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create}
    Draper::ViewContext.current = c.view_context
  end

  subject(:decorator) { described_class.new(group) }

  let(:mitglied) { Group::SektionsMitglieder::Mitglied.sti_name }
  let(:mitglied_zusatzsektion) { Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name }
  let(:neuanmeldung_nv) { Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name }
  let(:neuanmeldung_sektion) { Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name }
  let(:neuanmeldung_nv_zusatzsektion) {
 Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name }
  let(:neuanmeldung_sektion_zusatzsektion) {
 Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name }

  def count_roles(*types)
    group.children.map {|subgroup| subgroup.roles.where(type: types).count }.sum
  end

  def make_person(group)
    Fabricate(:person, birthday: 25.years.ago, primary_group_id: group.id)
  end

  describe '#members_count' do
    context 'for Sektion' do
      let(:group) { groups(:bluemlisalp) }

      it 'counts Mitglied roles' do
        expect(count_roles(mitglied)).to eq(4)
        expect(count_roles(mitglied_zusatzsektion)).to eq(0)

        expect(decorator.members_count).to eq(4)
      end

      it 'counts MitgliedZusatzsektion roles' do
        person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), person: person)
        Fabricate(mitglied_zusatzsektion, group: groups(:bluemlisalp_mitglieder), person: person)

        expect(count_roles(mitglied)).to eq(4)
        expect(count_roles(mitglied_zusatzsektion)).to eq(1)

        expect(decorator.members_count).to eq(5)
      end

      it 'does not count Neuanmeldung roles' do
        neuanmeldung_nv_person = make_person(groups(:bluemlisalp_neuanmeldungen_nv))
        Fabricate(neuanmeldung_nv, group: groups(:bluemlisalp_neuanmeldungen_nv), 
person: neuanmeldung_nv_person)

        neuanmeldung_nv_zusatzsektion_person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), 
person: neuanmeldung_nv_zusatzsektion_person)
        Fabricate(neuanmeldung_nv_zusatzsektion, group: groups(:bluemlisalp_neuanmeldungen_nv), 
person: neuanmeldung_nv_zusatzsektion_person)

        neuanmeldung_sektion_person = make_person(groups(:bluemlisalp_neuanmeldungen_sektion))
        Fabricate(neuanmeldung_sektion, group: groups(:bluemlisalp_neuanmeldungen_sektion), 
person: neuanmeldung_sektion_person)

        neuanmeldung_sektion_zusatzsektion_person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), 
person: neuanmeldung_sektion_zusatzsektion_person)
        Fabricate(neuanmeldung_sektion_zusatzsektion, 
group: groups(:bluemlisalp_neuanmeldungen_sektion), person: neuanmeldung_sektion_zusatzsektion_person)

        expect(count_roles(mitglied, mitglied_zusatzsektion)).to eq(4)

        expect(decorator.members_count).to eq(4)
      end

      it 'does not count Mitglied and MitgliedZusatzsektion roles of nested Ortsgruppe' do
        mitglied_person = make_person(groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))
        Fabricate(mitglied, group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), 
person: mitglied_person)

        mitglied_zusatzsektion_person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), 
person: mitglied_zusatzsektion_person)
        Fabricate(mitglied_zusatzsektion, 
group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: mitglied_zusatzsektion_person)

        expect(count_roles(mitglied, mitglied_zusatzsektion)).to eq(4)

        expect(decorator.members_count).to eq(4)
      end
    end

    context 'for Ortsgruppe' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

      it 'counts Mitglied roles' do
        person = make_person(groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))
        Fabricate(mitglied, group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), 
person: person)

        expect(count_roles(mitglied)).to eq(1)

        expect(decorator.members_count).to eq(1)
      end

      it 'counts MitgliedZusatzsektion roles' do
        person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), person: person)
        Fabricate(mitglied_zusatzsektion, 
group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder), person: person)

        expect(count_roles(mitglied)).to eq(0)
        expect(count_roles(mitglied_zusatzsektion)).to eq(1)

        expect(decorator.members_count).to eq(1)
      end

      it 'does not count Neuanmeldung and Neuanmeldung roles' do
        ausserberg_neuanmeldungen_sektion =
          Fabricate(Group::SektionsNeuanmeldungenSektion.sti_name, 
parent: groups(:bluemlisalp_ortsgruppe_ausserberg))

        neuanmeldung_nv_person = make_person(groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv))
        Fabricate(neuanmeldung_nv, 
group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv), person: neuanmeldung_nv_person)

        neuanmeldung_nv_zusatzsektion_person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), 
person: neuanmeldung_nv_zusatzsektion_person)
        Fabricate(neuanmeldung_nv_zusatzsektion, 
group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv), person: neuanmeldung_nv_zusatzsektion_person)

        neuanmeldung_sektion_person = make_person(ausserberg_neuanmeldungen_sektion)
        Fabricate(neuanmeldung_sektion, group: ausserberg_neuanmeldungen_sektion, 
person: neuanmeldung_sektion_person)

        neuanmeldung_sektion_zusatzsektion_person = make_person(groups(:matterhorn_mitglieder))
        Fabricate(mitglied, group: groups(:matterhorn_mitglieder), 
person: neuanmeldung_sektion_zusatzsektion_person)
        Fabricate(neuanmeldung_sektion_zusatzsektion, group: ausserberg_neuanmeldungen_sektion, 
person: neuanmeldung_sektion_zusatzsektion_person)

        expect(count_roles(mitglied, mitglied_zusatzsektion)).to eq(0)

        expect(decorator.members_count).to eq(0)
      end
    end

    context 'for other group types' do
      let(:group) { groups(:geschaeftsstelle) }

      it 'returns nil' do
        expect(decorator.members_count).to be_nil
      end
    end
  end

  describe '#membership_admission_through_gs?' do
    context 'for Sektion' do
      let(:group) { groups(:bluemlisalp) }

      it 'returns true without child SektionsNeuanmeldungenSektion' do
        group.children.where(type: Group::SektionsNeuanmeldungenSektion.sti_name).delete_all

        expect(decorator.membership_admission_through_gs?).to eq true
      end

      it 'returns false with child SektionsNeuanmeldungenSektion' do
        expect(group.children.where(type: Group::SektionsNeuanmeldungenSektion.sti_name)).to be_exists

        expect(decorator.membership_admission_through_gs?).to eq false
      end
    end

    context 'for Ortsgruppe' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

      it 'returns true without child SektionsNeuanmeldungenSektion' do
        expect(group.children.where(type: Group::SektionsNeuanmeldungenSektion.sti_name)).not_to be_exists

        expect(decorator.membership_admission_through_gs?).to eq true
      end

      it 'returns false with child SektionsNeuanmeldungenSektion' do
        ausserberg_neuanmeldungen_sektion =
          Fabricate(Group::SektionsNeuanmeldungenSektion.sti_name, 
parent: groups(:bluemlisalp_ortsgruppe_ausserberg))

        expect(group.children.where(type: Group::SektionsNeuanmeldungenSektion.sti_name)).to be_exists

        expect(decorator.membership_admission_through_gs?).to eq false
      end
    end

    context 'for other group types' do
      let(:group) { groups(:geschaeftsstelle) }

      it 'returns nil' do
        expect(decorator.membership_admission_through_gs?).to be_nil
      end
    end
  end

  describe '#membership_self_registration_url' do
    let(:host) { Rails.configuration.action_mailer.default_url_options[:host] }

    context 'for Sektion' do
      let(:group) { groups(:bluemlisalp) }

      it 'returns self registration url' do
        expect(group).to respond_to(:sac_cas_self_registration_url)

        expect(decorator.membership_self_registration_url).
          to eq group.sac_cas_self_registration_url(host)
      end
    end

    context 'for Ortsgruppe' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

      it 'returns self registration url' do
        expect(group).to respond_to(:sac_cas_self_registration_url)

        expect(decorator.membership_self_registration_url)
          .to eq group.sac_cas_self_registration_url(host)
      end
    end

    context 'for other group types' do
      let(:group) { groups(:geschaeftsstelle) }

      it 'returns nil' do
        expect(group).not_to respond_to(:sac_cas_self_registration_url)

        expect(decorator.membership_self_registration_url).to be_nil
      end
    end
  end

  describe '#social_accounts' do
    context 'for Sektion' do
      let(:group) { groups(:bluemlisalp) }

      it 'returns true with social account label Homepage JO' do
        Fabricate(:social_account, contactable: group, label: 'Homepage JO')

        expect(decorator.has_youth_organization?).to eq true
      end

      it 'returns false without social account label Homepage JO' do
        expect(group.social_accounts.where(label: 'Homepage JO')).not_to be_exists
        Fabricate(:social_account, contactable: group, label: 'Homepage')

        expect(decorator.has_youth_organization?).to eq false
      end
    end

    context 'for Ortsgruppe' do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

      it 'returns true with social account label Homepage JO' do
        Fabricate(:social_account, contactable: group, label: 'Homepage JO')

        expect(decorator.has_youth_organization?).to eq true
      end

      it 'returns false without social account label Homepage JO' do
        expect(group.social_accounts.where(label: 'Homepage JO')).not_to be_exists
        Fabricate(:social_account, contactable: group, label: 'Homepage')

        expect(decorator.has_youth_organization?).to eq false
      end
    end

    context 'for other group types' do
      let(:group) { groups(:geschaeftsstelle) }

      it 'returns nil' do
        Fabricate(:social_account, contactable: group, label: 'Homepage JO')

        expect(decorator.has_youth_organization?).to eq nil
      end
    end
  end
end
