# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string           not null
#  label                 :string           not null
#  placeholders_optional :string
#  placeholders_required :string
#  subject               :string
#

module SacCas::CustomContent
  extend ActiveSupport::Concern

  SECTION_SPECIFIC_CONTENTS_FILE =
    HitobitoSacCas::Wagon.root.join("db/seeds/sac_section_custom_contents.yml")

  def body_with_values(placeholders = {})
    body.to_s.html_safe
      .then { RenderMarkdownTables.replace_markdown_tables(_1) }
      .then { replace_placeholders(_1, placeholders) }
  end

  module ClassMethods
    def init_section_specific_contents(group)
      section_specific_templates.each do |key, attrs|
        entry = group.custom_contents.find_or_initialize_by(key: key)

        entry.attributes = attrs.slice("label", "placeholders_optional", "placeholders_required")
        if entry.new_record?
          entry.subject = attrs["subject"]
          entry.body = attrs["body"].split("\n").join("<br>")
        end
        entry.save!
      end
    end

    def section_specific_templates
      YAML.load_file(SECTION_SPECIFIC_CONTENTS_FILE)
    end
  end
end
