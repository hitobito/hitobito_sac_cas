# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::SektionenImporter do
  let(:file) { file_fixture('sektionen.xlsx') }
  let(:importer) { described_class.new(file, output: double(puts: nil)) }
  let(:bluemlisalp) { Group::Sektion.find_by!(navision_id: 1650) }
  let(:ortsgruppe) { Group::Ortsgruppe.find_by!(navision_id: 1651) }
  let(:matterhorn) { Group::Sektion.find_by!(navision_id: 4242) }
  let(:existing_bluemlisalp) { groups(:bluemlisalp) }

  before do
    clear_sektion_fixtures
  end

  it 'imports sections' do
    expect { importer.import! }.
      to change { Group::Sektion.count }.by(2).
      and change { Group::Ortsgruppe.count }.by(1)
  end

  it 'imports section attributes' do
    importer.import!

    expect(bluemlisalp.section_canton).to eq('BE')
    expect(bluemlisalp.foundation_year).to eq(1874)
    expect(bluemlisalp.language).to eq('DE')

    expect(matterhorn.section_canton).to eq('VS')
    expect(matterhorn.foundation_year).to eq(1988)
    expect(matterhorn.language).to eq('DE')
  end

  it 'adds neuanmeldungen and enables self registration' do
    importer.import!

    neuanmeldungen = Group::SektionsNeuanmeldungenNv.find_by!(parent_id: bluemlisalp.id)
    expect(neuanmeldungen.custom_self_registration_title).to eq('Registrierung zu SAC Blüemlisalp')
    expect(neuanmeldungen.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s)

    neuanmeldungen_ortsgruppe = Group::SektionsNeuanmeldungenNv.find_by!(parent_id: ortsgruppe.id)
    expect(neuanmeldungen_ortsgruppe.custom_self_registration_title).to eq('Registrierung zu SAC Blüemlisalp Ausserberg')
    expect(neuanmeldungen_ortsgruppe.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s)

    neuanmeldungen_sektion_matterhorn = Group::SektionsNeuanmeldungenSektion.find_by!(parent_id: matterhorn.id)
    expect(neuanmeldungen_sektion_matterhorn.custom_self_registration_title).to eq('Registrierung zu SAC Matterhorn')
    expect(neuanmeldungen_sektion_matterhorn.self_registration_role_type).to eq(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.to_s)

    neuanmeldungen_matterhorn = Group::SektionsNeuanmeldungenNv.find_by!(parent_id: matterhorn.id)
    expect(neuanmeldungen_matterhorn.custom_self_registration_title).to eq(nil)
    expect(neuanmeldungen_matterhorn.self_registration_role_type).to eq(nil)
  end

  it 'creates sac default sub groups for sektion + a ortsgruppe as sub group' do
    importer.import!

    expected_sub_groups = [Group::SektionsNeuanmeldungenNv,
                           Group::SektionsMitglieder,
                           Group::SektionsExterneKontakte,
                           Group::SektionsTourenkommission,
                           Group::SektionsFunktionaere]

    expected_sub_group_count = expected_sub_groups.count + 1
    expect(bluemlisalp.children.count).to eq(expected_sub_group_count)

    expected_sub_groups.each do |c|
      expect(c.where(parent_id: bluemlisalp.id).count).to eq(1)
    end
  end

  it 'creates sac default sub groups for sektion with neuanmeldung sektion' do
    importer.import!

    expected_sub_groups = [Group::SektionsNeuanmeldungenNv,
                           Group::SektionsNeuanmeldungenSektion,
                           Group::SektionsMitglieder,
                           Group::SektionsExterneKontakte,
                           Group::SektionsTourenkommission,
                           Group::SektionsFunktionaere]

    expected_sub_group_count = expected_sub_groups.count
    expect(matterhorn.children.count).to eq(expected_sub_group_count)

    expected_sub_groups.each do |c|
      expect(c.where(parent_id: matterhorn.id).count).to eq(1)
    end
  end

  it 'creates ortsgruppe with default sub groups' do
    importer.import!

    expect(ortsgruppe.section_canton).to eq('VS')
    expect(ortsgruppe.foundation_year).to eq(1975)

    expected_sub_groups = [
      Group::SektionsFunktionaere,
      Group::SektionsMitglieder,
      Group::SektionsNeuanmeldungenNv,
      Group::SektionsExterneKontakte,
      Group::SektionsTourenkommission
    ]

    expected_sub_group_count = expected_sub_groups.count
    expect(ortsgruppe.children.count).to eq(expected_sub_group_count)

    expected_sub_groups.each do |c|
      expect(c.where(parent_id: ortsgruppe.id).count).to eq(1)
    end
  end

  describe '#set_language' do
    it 'does not set for group without required mounted attr' do
      group = Group::SacCas.new

      importer.send(:set_language, { locale: 'ITS' }, group)

      expect(group.respond_to?(:language)).to eq(false)
    end

    it 'sets DE for DES' do
      group = Group::Sektion.new
      importer.send(:set_language, { locale: 'DES' }, group)

      expect(group.language).to eq('DE')
    end

    it 'sets FR for FRS' do
      group = Group::Sektion.new
      importer.send(:set_language, { locale: 'FRS' }, group)

      expect(group.language).to eq('FR')
    end

    it 'sets IT for ITS' do
      group = Group::Sektion.new
      importer.send(:set_language, { locale: 'ITS' }, group)

      expect(group.language).to eq('IT')
    end

    it 'falls back to DE' do
      group = Group::Sektion.new
      importer.send(:set_language, { locale: '' }, group)

      expect(group.language).to eq('DE')

      importer.send(:set_language, { locale: nil }, group)

      expect(group.language).to eq('DE')
    end
  end

  private

  def clear_sektion_fixtures
    Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
    Group::Sektion.all.find_each { |s| s.really_destroy! }
    Group::Ortsgruppe.with_deleted.delete_all
    Group::Sektion.with_deleted.delete_all
  end
end
