# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::StepsComponent::ContentComponent
  extend ActiveSupport::Concern

  def fields_for(&block)
    @form.fields_for(@partial.split('/').last, model, &block)
  end

  def model
    @form.object.step_at(index)
  end

  def attr?(key)
    return false if key == :email && @partial =~ /main_person/

    super
  end
end
