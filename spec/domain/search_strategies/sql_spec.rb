#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SearchStrategies::Sql do

  subject { described_class.new(user, term, page) }
  let(:term) { 'test' }
  let(:page) { 0 }

  describe '#query_people' do

    context 'as root' do
      let(:user) { people(:root) }

      it 'does not attempt to list all accessible person ids' do
        expect(subject).not_to receive(:query_accessible_people)

        subject.query_people
      end
    end

    context 'as geschaeftsstelle admin' do
      let(:user) { people(:admin) }

      it 'does not attempt to list all accessible person ids' do
        expect(subject).not_to receive(:query_accessible_people)

        subject.query_people
      end
    end

    context 'as geschaeftsstelle mitarbeiter' do
      let(:user) { Fabricate(:person) }
      let!(:role) { Fabricate(:role, type: Group::Geschaeftsstelle::Mitarbeiter.name, group: groups(:geschaeftsstelle), person: user) }

      it 'does not attempt to list all accessible person ids' do
        expect(subject).not_to receive(:query_accessible_people)

        subject.query_people
      end
    end

    context 'as geschaeftsstelle mitarbeiter lesend' do
      let(:user) { Fabricate(:person) }
      let!(:role) { Fabricate(:role, type: Group::Geschaeftsstelle::MitarbeiterLesend.name, group: groups(:geschaeftsstelle), person: user) }

      it 'does not attempt to list all accessible person ids' do
        expect(subject).not_to receive(:query_accessible_people)

        subject.query_people
      end
    end

    context 'as unprivileged person' do
      let(:user) { Fabricate(:person) }

      it 'lists all accessible person ids' do
        expect(subject).to receive(:query_accessible_people)

        subject.query_people
      end
    end

  end

end
