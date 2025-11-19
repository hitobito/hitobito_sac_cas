#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class People::Export::PeriodForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :group

  attribute :from, :date, default: -> { Date.current.beginning_of_year }
  attribute :to, :date, default: -> { Date.current.end_of_year }

  validates_date :to, after: :from
  validates_date :to, before: ->(m) { m.from + 1.year }
end
