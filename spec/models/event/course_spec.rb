# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::Course do
  describe '::validations' do
    subject(:course) do
      course = Fabricate.build(:sac_course)
      course.dates.build(start_at: Time.zone.local(2012, 5, 11))
      course
    end

    it 'validates presence of number' do
      course.number = nil
      expect(course).not_to be_valid
      expect(course.errors[:number]).to eq ['muss ausgefüllt werden']
    end

    it 'validates uniqueness of number' do
      events(:top_course).update_columns(number: 1)
      course.number = 1
      expect(course).not_to be_valid
      expect(course.errors[:number]).to eq ['ist bereits vergeben']
    end

    it 'validates presence of location in state ready' do
      course.state = :ready
      expect(course).not_to be_valid
      expect(course.errors[:location]).to eq ['muss ausgefüllt werden']
    end

    it 'does not validate presence of location in state created' do
      course.state = :created
      expect(course).to be_valid
    end
  end

  describe '#used_attributes' do
    it 'has expected additions' do
      expect(described_class.used_attributes).to include(
        :accommodation,
        :annual,
        :cost_center_id,
        :cost_unit_id,
        :language,
        :link_leaders,
        :link_participants,
        :link_survey,
        :minimum_age,
        :reserve_accommodation, :season,
        :start_point_of_time
      )
    end

    it 'has expected removals' do
      expect(described_class.used_attributes).not_to include(:cost)
    end
  end

  describe '#i18n_enums' do
    it 'language is configured as an i18n_enum' do
      expect(described_class.language_labels).to eq [
        [:de_fr, 'Deutsch/Französisch'],
        [:de, 'Deutsch'],
        [:fr, 'Französisch'],
        [:it, 'Italienisch'],
      ].to_h
    end

    it 'accommodation is configured as an i18n_enum' do
      expect(described_class.accommodation_labels).to eq [
        [:bivouac, 'Übernachtung im Freien/Biwak'],
        [:hut, 'Hütte'],
        [:no_overnight, 'ohne Übernachtung'],
        [:pension, 'Pension/Berggasthaus'],
        [:pension_or_hut, 'Pension/Berggasthaus oder Hütte'],
      ].to_h
    end

    it 'start_point_of_time is configured as an i18n_enum' do
      expect(described_class.start_point_of_time_labels).to eq [
        [:day, 'Tag'],
        [:evening, 'Abend']
      ].to_h
    end

    it 'season is configure as an i18n_enum' do
      expect(described_class.season_labels).to eq [
        [:summer, 'Sommer'],
        [:winter, 'Winter']
      ].to_h
    end
  end

  describe '#minimum_age' do
    subject(:course) { described_class.new }

    it 'is read from course not kind' do
      expect(course.minimum_age).to be_nil
      course.kind = Event::Kind.new(minimum_age: 1)
      expect(course.minimum_age).to be_nil
      course.minimum_age = 2
      expect(course.minimum_age).to eq 2
    end
  end

  describe '#level' do
    subject(:course) { Fabricate(:sac_course) }

    it 'returns value from kind' do
      expect(course.level).to eq event_levels(:ek)
    end

    it 'does not fail when kind level is nil' do
      course.kind.level = nil
      expect(course.level).to be_nil
    end
  end

  describe 'application_closing_at dependent state transitions' do
    let(:course) { events(:closed) }

    describe 'application_open' do
      before { course.update_columns(state: 'application_open') }

      it 'closes course if closing date changes to past' do
        course.update!(application_closing_at: Time.zone.yesterday)
        expect(course.state).to eq 'application_closed'
      end

      it 'does not change state course if closing date changes to today' do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq 'application_open'
      end

      it 'does not change state course if closing date changes to future' do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq 'application_open'
      end
    end

    # does not work as expected, validations are build using states defined in youth wagon
    describe 'application_paused' do
      before { course.update_columns(state: 'application_open') }

      it 'closes course if closing date changes to past' do
        course.update!(application_closing_at: Time.zone.yesterday)
        expect(course.state).to eq 'application_closed'
      end

      it 'does not change state course if closing date changes to today' do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq 'application_open'
      end

      it 'does not change state course if closing date changes to future' do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq 'application_open'
      end
    end

    describe 'application_closed state' do
      before { course.update_columns(state: 'application_closed') }

      it 'does not change state if closing date changes to past' do
        course.update!(application_closing_at: Time.zone.yesterday)

        expect(course.state).to eq 'application_closed'
      end

      it 'does not change state if closing date changes to today' do
        course.update!(application_closing_at: Time.zone.today)
        expect(course.state).to eq 'application_closed'
      end

      it 'opens course for application state if closing date changes to future' do
        course.update!(application_closing_at: Time.zone.tomorrow)
        expect(course.state).to eq 'application_open'
      end
    end
  end
end
