require 'spec_helper'

describe EventsHelper do
  include FormatHelper

  describe '#format_event_application_conditions' do
    let(:kind) { Fabricate.build(:event_kind, application_conditions: 'kind conditions') }
    let(:event) { Fabricate.build(:course, kind: kind, application_conditions: 'event conditions') }

    it 'does not render kind application conditions' do
      text = format_event_application_conditions(event)
      expect(text).to eq 'event conditions'
    end

    it 'does sill auto link' do
      event.application_conditions = 'see www.hitobito.ch'
      text = format_event_application_conditions(event)
      expect(text).to eq 'see <a target="_blank" href="http://www.hitobito.ch">www.hitobito.ch</a>'
    end
  end

end
