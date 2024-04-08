require 'spec_helper'

describe Events::Courses::StateStepper do

  subject { described_class.new(@course) }

  context '#available_steps' do
    it 'shows available steps' do
      @course = events(:closed)

      expect(subject.available_steps).to eq([:assignment_closed, :canceled])
    end

    it 'does not show step that makes course invalid' do
      @course = events(:top_course)

      expect(subject.available_steps).to eq([])
    end
  end

end
