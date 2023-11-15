# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Sequence < ApplicationRecord
  def self.by_name(name)
    where(name: name).first_or_create!
  end

  def self.current_value(name)
    by_name(name).current_value
  end

  def self.increment!(name)
    by_name(name).increment!
  end

  def increment!
    with_lock { update!(current_value: current_value + 1) }
    current_value
  end
end
