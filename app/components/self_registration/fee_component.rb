# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::FeeComponent < ApplicationComponent
  attr_reader :group, :birthdays

  def initialize(group:, birthdays: []) # rubocop:disable Lint/MissingSuper
    @group = group
    @birthdays = birthdays
  end

  def title
    t(".title", group: @group.layer_group)
  end

  def annual_fee
    "CHF 122 - jährlicher Beitrag"
  end

  def inscription_fee
    "CHF 30 - einmalige Gebühr"
  end

  def total
    "CHF 152 - Total"
  end
end
