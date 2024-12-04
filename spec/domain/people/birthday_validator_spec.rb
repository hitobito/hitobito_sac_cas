# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::BirthdayValidator do
  let(:person) { people(:mitglied) }
  let(:current_user) { people(:mitglied) }
  let(:validator) { described_class.new(person, current_user) }

  before do
    travel_to "06.06.2005"
  end

  it "adds no error when exactly six years old" do
    person.update!(birthday: Date.parse("06.06.1999"))
    expect { validator.validate_birthday_range }.not_to throw_symbol(:abort)
    expect(person.errors[:birthday]).to be_empty
  end

  it "adds error when 5 years and 364 days old" do
    person.update!(birthday: Date.parse("07.06.1999"))
    expect { validator.validate_birthday_range }.to throw_symbol(:abort)
    expect(person.errors[:birthday]).to eq ["muss vor dem 06.06.1999 liegen."]
  end

  it "adds no error when exactly 119 years and 364 days old" do
    person.update!(birthday: Date.parse("07.06.1885"))
    expect { validator.validate_birthday_range }.not_to throw_symbol(:abort)
    expect(person.errors[:birthday]).to be_empty
  end

  it "adds error when over 120 years old" do
    person.update!(birthday: Date.parse("05.06.1885"))
    expect { validator.validate_birthday_range }.to throw_symbol(:abort)
    expect(person.errors[:birthday]).to eq ["muss nach dem 06.06.1885 liegen."]
  end

  context "backoffice" do
    let(:current_user) { people(:admin) }

    it "adds error if blan" do
      person.birthday = nil
      expect { validator.validate! }.to throw_symbol(:abort)
      expect(person.errors[:birthday]).to eq ["muss ausgefüllt werden"]
    end
  end
end
