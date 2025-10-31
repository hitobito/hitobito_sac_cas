#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Export::JubilareForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :group

  attribute :reference_date, :date, default: -> { Date.current.end_of_year }
  attribute :membership_years, :integer

  validates :reference_date, presence: true
end
