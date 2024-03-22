# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require 'spec_helper'

describe PeopleManagerAbility do

  let(:user) { people(:admin) }
  subject(:ability) { Ability.new(user) }

  def build(managed: nil, manager: nil)
    PeopleManager.new(managed: managed, manager: manager)
  end

  def create_person(**opts)
    Fabricate(:person, primary_group: groups(:externe_kontakte), **opts).tap do |person|
      # add a role to make the person findable
      Group::ExterneKontakte::Kontakt.create!(person: person, group: groups(:externe_kontakte))
    end
  end

  let(:adult) { create_person(birthday: 25.years.ago) }
  let(:other_adult) { create_person(birthday: 25.years.ago) }
  let(:child) { create_person(birthday: 15.years.ago) }
  let(:other_child) { create_person(birthday: 15.years.ago) }

  it 'may not create manager on adult' do
    expect(ability).not_to be_able_to(:create_manager, build(manager: adult, managed: other_adult))
  end

  it 'may not create manager on child' do
    expect(ability).not_to be_able_to(:create_manager, build(manager: adult, managed: child))
  end

  it 'may not create managed on child' do
    expect(ability).not_to be_able_to(:create_managed, build(manager: child, managed: other_child))
  end

  it 'may create managed on adult' do
    expect(ability).to be_able_to(:create_managed, build(manager: adult, managed: child))
  end

end
