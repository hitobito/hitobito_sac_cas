# frozen_string_literal: true

#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::MainEmail do
  let(:params) { {} }
  let(:wizard) { instance_double(Wizards::Base, current_user: nil) }
  let(:subject) { described_class.new(wizard, **params) }

  describe "validations" do
    context "without email" do
      it do
        is_expected.not_to be_valid
        expect(subject.errors[:email].count).to eq 1
      end
    end

    context "with invalid email" do
      before { allow(Truemail).to receive(:valid?).and_return(false) }

      it do
        is_expected.not_to be_valid
        expect(subject.errors[:email].count).to eq 1
      end
    end

    context "with valid email" do
      let(:params) { {email: "foo@bar.ch"} }

      it { is_expected.to be_valid }

      context "when email is already taken" do
        before { Fabricate(:person, email: params[:email]) }

        it do
          is_expected.not_to be_valid
          expect(subject.errors[:email].count).to eq 1
        end
      end
    end
  end
end
