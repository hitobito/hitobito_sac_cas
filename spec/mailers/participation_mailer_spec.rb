# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationMailer do
  let(:person) { people(:mitglied) }
  let(:event) { Fabricate(:event) }
  let(:participation) { Fabricate(:event_participation, event: event, person: person) }
  let(:mail) { Event::ParticipationMailer.confirmation(participation) }

  before do
    Fabricate(:phone_number, contactable: person, public: true)
  end

  subject { mail.parts.first.body }

  describe '#rejection' do
    subject { mail.body }
    let(:mail) { Event::ParticipationMailer.reject(participation) }

    it 'sends to email addresses of declined participant' do
      expect(mail.to).to match_array(['e.hillary@hitobito.example.com'])
      expect(mail.subject).to eq 'Kursablehnung'
    end

    it { is_expected.to match(/Hallo Edmund Hillary/) }
    it { is_expected.to match(/Sie wurden leider für den Kurs Eventus abgelehnt/) }
  end
end
