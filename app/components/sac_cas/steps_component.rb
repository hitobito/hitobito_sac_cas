# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::StepsComponent
  extend ActiveSupport::Concern

  prepended do
    haml_template <<~HAML
      %div{data: { controller: stimulus_controller} }
        = hidden_field_tag(:step, @step, data: stimulus_target('step'))
        = hidden_field_tag :autosubmit, ''
        .row
          %ol.step-headers.offset-md-1
            = render(HeaderComponent.with_collection(@partials, step: @step))
        .row
          - if @form.object.is_a?(SelfRegistration::Sektion)
            .col-lg= render(ContentComponent.with_collection(@partials, step: @step, form: @form))
            .col-md
              = render(SelfRegistration::FeeComponent.new(group: @form.object.group, birthdays: @form.object.birthdays))
              = render(SelfRegistration::InfosComponent.new)
          - else
            .col= render(ContentComponent.with_collection(@partials, step: @step, form: @form))
    HAML
  end
end
