# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class JsonApi::Event::LevelsController < JsonApiController
  def index
    authorize!(:index, Event::Level)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  private

  def entry
    @entry ||= Event::Level.find(params[:id])
  end
end
