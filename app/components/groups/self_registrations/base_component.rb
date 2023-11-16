# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistrations::BaseComponent < ApplicationComponent

  attr_reader :form

  def initialize(form:, policy_finder:, active:)
    @form = form
    @policy_finder = policy_finder
    @active = active
  end

  def entry
    form.object
  end

  def required
    # TODO return @active here and get the nested form to work with HTML5 required attributes
    false
  end

  def self.valid?(entry)
    # Override in specific component
    true
  end

end
