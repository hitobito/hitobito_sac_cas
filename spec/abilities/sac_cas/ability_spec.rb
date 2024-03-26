# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Ability do
  before { MailingListSeeder.seed! }

  %i[root admin].each do |person_key|
    context "as #{person_key}" do
      let(:ability) { Ability.new(people(person_key)) }

      context 'groups' do
        let(:group) { groups(:root) }

        it 'can update group' do
          expect(ability).to be_able_to(:update, group)
        end

        it 'cannot update group#sac_newsletter_mailing_list_id' do
          attr = :sac_newsletter_mailing_list_id
          # first let's make sure we still have the correct attribute
          expect(group).to respond_to(:"#{attr}=")
          expect(ability).not_to be_able_to(:update, group, attr)
        end
      end

      context 'mailing_lists' do
        let(:a_mailing_list) { Fabricate(:mailing_list, group: groups(:root)) }
        let(:newsletter) do
          MailingList.find_by(internal_key: SacCas::NEWSLETTER_MAILING_LIST_INTERNAL_KEY)
        end

        it 'can update mailing list' do
          expect(ability).to be_able_to(:update, a_mailing_list)
        end

        it 'can destroy mailing list' do
          expect(ability).to be_able_to(:destroy, a_mailing_list)
        end

        it 'can update newsletter mailing list' do
          expect(ability).to be_able_to(:update, newsletter)
        end

        it 'cannot update newsletter mailing list subscribable_for' do
          expect(ability).not_to be_able_to(:update, newsletter, :subscribable_for)
        end

        it 'cannot update newsletter mailing list subscribable_mode' do
          expect(ability).not_to be_able_to(:update, newsletter, :subscribable_mode)
        end

        it 'cannot update newsletter mailing list filter_chain' do
          expect(ability).not_to be_able_to(:update, newsletter, :filter_chain)
        end

        it 'cannot destroy newsletter mailing list' do
          expect(ability).not_to be_able_to(:destroy, newsletter)
        end

        it 'can update mailing list subscription' do
          expect(ability).to be_able_to(:update, Subscription.new(mailing_list: a_mailing_list))
        end

        it 'can destroy mailing list subscription' do
          expect(ability).to be_able_to(:destroy, Subscription.new(mailing_list: a_mailing_list))
        end

        it 'cannot update newsletter mailing list subscription' do
          expect(ability).not_to be_able_to(:update, Subscription.new(mailing_list: newsletter))
        end

        it 'cannot destroy newsletter mailing list subscription' do
          expect(ability).not_to be_able_to(:destroy, Subscription.new(mailing_list: newsletter))
        end
      end
    end

  end
end
