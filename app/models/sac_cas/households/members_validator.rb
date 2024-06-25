# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module SacCas::Households::MembersValidator
  extend ActiveSupport::Concern

  def validate(household)
    super
    assert_someone_is_a_member
  end

  private

  def assert_someone_is_a_member
    someone_is_member = members.any? { |member| People::SacMembership.new(member.person).active? }
    unless someone_is_member
      @household.errors.add(:members, :no_members)
    end
  end
end
