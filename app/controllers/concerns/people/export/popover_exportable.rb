# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People::Export::PopoverExportable
  def create
    authorize!(:index_people, group)

    entry.attributes = model_params
    if entry.valid?
      export_in_background
    else
      rerender_form(:unprocessable_content)
    end
  end

  private

  def export_in_background
    with_async_download_cookie(
      :xlsx,
      filename,
      redirection_target: group_people_path(group, returning: true)
    ) do |name|
      enqueue_job(name)
    end
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def sektion
    group.layer_group
  end
end
