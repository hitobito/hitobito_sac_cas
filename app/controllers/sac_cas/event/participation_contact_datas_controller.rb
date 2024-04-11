# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::ParticipationContactDatasController
  extend ActiveSupport::Concern

  prepended do
    layout :derrive_layout, only: :edit
  end

  def edit
    request.variant = :course if event.course?
    super
  end

  private

  def derrive_layout
    event.course? ? 'course_signup' : 'application'
  end
end
