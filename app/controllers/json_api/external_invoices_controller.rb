# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and
#  licensed under the Affero General Public License version 3 or later. See the
#  COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::ExternalInvoicesController < JsonApiController
  def index
    authorize!(:index, ExternalInvoice)
    super
  end

  def show
    authorize!(:show, entry)
    super
  end

  def update
    authorize!(:update, entry)
    super
  end

  private

  def entry
    @entry ||= ExternalInvoice.accessible_by(current_ability).find(params[:id])
  end
end
