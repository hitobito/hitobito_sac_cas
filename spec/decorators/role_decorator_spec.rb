# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

describe RoleDecorator, :draper_with_helpers do
  let(:decorator) { described_class.new(role) }

  describe '#for_aside' do
    subject(:node) { Capybara::Node::Simple.new(decorator.for_aside) }
    context 'mitglied role' do
      let(:role) { roles(:mitglied) }

      it 'includes beitragskategorie' do
        expect(node).to have_css(:strong, text: 'Mitglied')
        expect(node).to have_css(:span, class: 'ms-1', text: '(Einzel)')
      end

      it 'includes label and beitragskategorie' do
        role.label = 'test'
        expect(node).to have_css(:strong, text: 'Mitglied')
        expect(node).to have_css(:span, class: 'ms-1', text: '(Einzel) (test)')
      end
    end

    context 'neuanmeldung role' do
    end

    context 'future mitglied role' do
      it 'includes beitragskategorie and start_on date' do
        expect(node).to have_css(:strong, text: 'Mitglied')
        expect(node).to have_css(:span, class: 'ms-1', text: '(Einzel) (ab 01.01.2025')
      end
    end

    context 'future neuanmeldung role' do
      it 'includes beitragskategorie and start_on date' do
        expect(node).to have_css(:strong, text: 'Mitglied')
        expect(node).to have_css(:span, class: 'ms-1', text: '(Einzel) (ab 01.01.2025')
      end
    end

    context 'non mitglied role' do
      let(:role) { roles(:admin) }

      it 'never includes beitragskategorie' do
      end
    end
  end

  describe '#for_history' do
    subject(:node) { Capybara::Node::Simple.new(decorator.for_history) }
    context 'mitglied role' do
      let(:role) { roles(:mitglied) }

      it 'includes beitragskategorie' do
        expect(node).to have_css(:strong, text: 'Mitglied')
        expect(node).to have_css(:span, class: 'ms-1', text: '(Einzel)')
      end
    end

    context 'neuanmeldung role' do
    end

    context 'future mitglied role' do
    end

    context 'non mitglied role' do
      let(:role) { roles(:admin) }

      it 'never includes beitragskategorie' do
      end
    end
  end
end
