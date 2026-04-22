# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacSectionCustomContentsController < SimpleCrudController
  self.nesting = Group

  self.permitted_attrs = [:body, :subject]

  self.sort_mappings = {label: "custom_content_translations.label",
                         subject: "custom_content_translations.subject"}

  decorates :custom_content

  skip_authorize_resource

  before_action :authorize_group_update

  class << self
    def model_class = CustomContent
  end

  private

  def model_scope
    parent.custom_contents
  end

  def authorize_class
    authorize_group_update
  end

  def authorize_group_update
    authorize!(:update, parent)
  end

  def index_path
    group_sac_section_custom_contents_path(parent, returning: true)
  end
end
