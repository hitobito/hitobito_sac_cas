# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::Level < ActiveRecord::Base
  validates_by_schema

  acts_as_paranoid

  translates :label
  validates :label, presence: true

  def to_s
    self.label
  end
end
