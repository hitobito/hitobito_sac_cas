# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ChangePeopleMembershipNumberDefault < ActiveRecord::Migration[6.1]
  def up
    Person.reset_column_information

    update_existing_people

    # make membership_number not null
    change_column :people, :membership_number, :integer, null: false

    # Add a unique index on the membership_number column
    add_index :people, :membership_number, unique: true
  end

  def down
    remove_index :people, :membership_number
    change_column_null :people, :membership_number, true
  end

  private

  def update_existing_people
    Person.where(membership_number: nil).each do |p|
      next_number = p.next_membership_number
      # use update_all to ignore attr_readonly :membership_number
      # in Person model
      Person.where(id: p.id).update_all(membership_number: next_number)
    end
  end
end
