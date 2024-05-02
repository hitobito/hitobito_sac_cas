require 'spec_helper'

describe Events::Courses::StateStepper do

  subject { described_class.new(@course) }

  context '#available_steps' do
    it 'shows available steps' do
      @course = events(:closed)

      expect(subject.available_steps).to eq([:assignment_closed, :canceled])
    end
  end

end
