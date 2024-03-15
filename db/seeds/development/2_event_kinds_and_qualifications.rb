# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'active_record/fixtures'


class EventsQualifactionsSeeder
  DUMMY_ID = 1
  REACTIVATABLE = { validity: 6, reactivateable: 4, required_training_days: 3 }
  TOURENCHEF_EDITABLE = { tourenchef_may_edit: true }

  QUALIFICATIONS = {
    'SAC Tourenleiter/in 1 Winter': REACTIVATABLE,
    'SAC Tourenleiter/in 2 Winter': REACTIVATABLE,
    'SAC Tourenleiter/in 1 Sommer': REACTIVATABLE,
    'SAC Tourenleiter/in 2 Sommer': REACTIVATABLE,
    'SAC Tourenleiter/in Sportklettern': REACTIVATABLE,
    'SAC Tourenleiter/in Alpinwandern': REACTIVATABLE,
    'SAC Tourenleiter/in Mountainbike': REACTIVATABLE,
    'SAC Tourenleiter/in Bergwandern': REACTIVATABLE,
    'Leiter/in Familienbergsteigen': REACTIVATABLE,
    'Bergführer/in SBV': TOURENCHEF_EDITABLE,
    'Kletterlehrer/in SBV': TOURENCHEF_EDITABLE,
    'Wanderleiter/in': TOURENCHEF_EDITABLE,
    'Schneeschuhleiter/in': TOURENCHEF_EDITABLE,
    'Mountainbikeleiter/in': TOURENCHEF_EDITABLE,
    'Diverse Leiter/in': TOURENCHEF_EDITABLE
  }

  EVENT_CATEGORIES_AND_KINDS = {
    'SAC Leiterausbildung Winter': [
      'Tourenleiter/in 1 Winter',
      'Tourenleiter/in 2 Winter'
    ],
    'SAC Leiterausbildung Sommer': [
      'Tourenleiter/in 1 Sommer',
      'Tourenleiter/in 2 Sommer',
      'Tourenleiter/in Bergwandern',
      'Tourenleiter/in Mountainbike'
    ],
    'SAC Leiterfortbildung Winter': [
      'Skitouren Freeride',
      'Skitourenleiter/in Winter - Refresher',
      'Rettung - Erste Hilfe',
      { training_days: 2 }
    ],
    'SAC Leiterfortbildung Sommer': [
      'Bergsteigen Sommer',
      'Entscheidungsfindung',
      'Rettung - Erste Hilfe',
      { training_days: 2 }
    ],
    'Skitechnik': [
      'Skitechnik Stufe 1',
      'Skitechnik Stufe 2',
      'Skitechnik Stufe 3',
      { training_days: 1 }
    ],
    'Lawinen': [
      'Lawinen Ski + Snowboard',
      'Lawinen Schneeschuhe',
      { training_days: 1 }
    ],
    'Sportklettern': [
      'Sportklettern',
    ],
    'Alpinwandern': [
      'Alpinwandern Stufe 1',
      'Alpinwandern Stufe 2',
    ]
  }.freeze

  PARTICIPANT_QUALIFYING = {category: :qualification, role: :participant}
  PARTICIPANT_QUALIFYING_EVENT_KINDS = {
    'Tourenleiter/in 1 Winter': [['SAC Tourenleiter/in 1 Winter'], PARTICIPANT_QUALIFYING],
    'Tourenleiter/in 2 Winter': [['SAC Tourenleiter/in 2 Winter'], PARTICIPANT_QUALIFYING],
    'Tourenleiter/in 1 Sommer': [['SAC Tourenleiter/in 1 Sommer'], PARTICIPANT_QUALIFYING],
    'Tourenleiter/in 2 Sommer': [['SAC Tourenleiter/in 2 Sommer'], PARTICIPANT_QUALIFYING],
    'Tourenleiter/in Bergwandern': [['SAC Tourenleiter/in Bergwandern'], PARTICIPANT_QUALIFYING],
    'Tourenleiter/in Mountainbike': [['SAC Tourenleiter/in Mountainbike'], PARTICIPANT_QUALIFYING],
  }

  LEADER_PROLONGING = [QUALIFICATIONS.keys, {category: :prolongation, role: :leader }]
  PARTICIPANT_PROLONGING = [QUALIFICATIONS.keys, {category: :prolongation, role: :participant }]

  PROLONGING_EVENT_KINDS = [
    'Skitouren Freeride',
    'Skitourenleiter/in Winter - Refresher',
    'Bergsteigen Sommer',
    'Entscheidungsfindung',
    'Rettung - Erste Hilfe',
    'Skitechnik Stufe 1',
    'Skitechnik Stufe 2',
    'Skitechnik Stufe 3',
    'Lawinen Ski + Snowboard',
    'Lawinen Schneeschuhe',
  ].product([PARTICIPANT_PROLONGING, LEADER_PROLONGING])


  def run
    seed_qualifications
    seed_qualification_translations

    seed_event_kind_categories
    seed_event_kind_category_translations

    seed_event_level
    seed_event_kinds
    seed_event_kind_translations

    seed_qualifying_event_kinds
    seed_prolonging_event_kinds
  end

  private

  def seed_qualifications
    attrs = QUALIFICATIONS.map { |label, options| options.merge(id: identify(label)) }
    QualificationKind.seed(:id, attrs)
  end

  def seed_qualification_translations
    attrs = QUALIFICATIONS.keys.map do |label|
      { locale: 'de', label: label, qualification_kind_id: identify(label) }
    end
    QualificationKind::Translation.seed(:qualification_kind_id, :locale, attrs)
  end

  def seed_event_level
    Event::Level.seed(:id, { id: DUMMY_ID,  code: 1, difficulty: 1 })
    Event::Level::Translation.seed(:event_level_id, { event_level_id: DUMMY_ID, locale: 'de', label: 'dummy' })
  end

  def seed_event_kinds
    rows = EVENT_CATEGORIES_AND_KINDS.flat_map do |category, kinds|
      options =  (kinds.last.is_a?(::Hash) ? kinds.pop : {})
        .merge(cost_center_id: DUMMY_ID, cost_unit_id: DUMMY_ID, level_id: DUMMY_ID)
      kinds.map { |kind| options.merge(id: identify(kind), kind_category_id: identify(category)) }
    end
    Event::Kind.seed(:id, rows)
  end

  def seed_event_kind_translations
    rows = EVENT_CATEGORIES_AND_KINDS.values.flat_map do |kinds|
      kinds.map do |kind|
        { locale: 'de', label: kind, event_kind_id: identify(kind) }
      end
    end
    Event::Kind::Translation.seed(:event_kind_id, rows)
  end

  def seed_event_kind_categories
    rows = EVENT_CATEGORIES_AND_KINDS.keys.map do |label|
      { id: identify(label), cost_center_id: DUMMY_ID, cost_unit_id: DUMMY_ID }
    end
    Event::KindCategory.seed(:id, rows)
  end

  def seed_event_kind_category_translations
    rows = EVENT_CATEGORIES_AND_KINDS.keys.map do |category|
      { locale: 'de', label: category, event_kind_category_id: identify(category) }
    end
    Event::KindCategory::Translation.seed(:event_kind_category_id, rows)
  end


  def seed_qualifying_event_kinds
    rows = build_kind_qualication_kinds(PARTICIPANT_QUALIFYING_EVENT_KINDS)
    Event::KindQualificationKind.seed(:id, rows)
  end

  def seed_prolonging_event_kinds
    rows = build_kind_qualication_kinds(PROLONGING_EVENT_KINDS)
    Event::KindQualificationKind.seed(:id, rows)
  end

  def build_kind_qualication_kinds(event_kind_qualifications)
    event_kind_qualifications.flat_map do |event_kind, (qualifications, options)|
      qualifications.map do |qualification|
        options.merge(
          id: next_kind_qualification_id,
          event_kind_id: identify(event_kind),
          qualification_kind_id: identify(qualification)
        )
      end
    end
  end

  def next_kind_qualification_id
    @kind_qualification_kind_id ||= 0
    @kind_qualification_kind_id +=1
  end

  def identify(key)
    ActiveRecord::FixtureSet.identify(key)
  end
end

EventsQualifactionsSeeder.new.run
