# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::AbilityDsl::Base
  extend ActiveSupport::Concern

  private

  def without_role(role_class)
    roles = user.roles.reject { |r| r.is_a?(role_class) }
    person = Person.new { |p| p.roles = roles }
    previous = @user_context
    @user_context = AbilityDsl::UserContext.new(person)
    yield.tap { @user_context = previous }
  end
end
