# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe GroupAbility do
  subject { Ability.new(person) }

  describe "create_yearly_membership_invoice" do
    context "as admin" do
      let(:person) { people(:admin) }

      it { is_expected.to be_able_to(:create_yearly_membership_invoice, groups(:bluemlisalp)) }
    end

    context "as mitglied" do
      let(:person) { people(:mitglied) }

      it { is_expected.not_to be_able_to(:create_yearly_membership_invoice, groups(:bluemlisalp)) }
    end

    describe "download_statistics" do
      context "as admin" do
        let(:person) { people(:admin) }

        it { is_expected.to be_able_to(:download_statistics, groups(:root)) }

        it { is_expected.not_to be_able_to(:download_statistics, groups(:bluemlisalp)) }
      end
    end
  end
end
