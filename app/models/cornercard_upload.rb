# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# == Schema Information
#
# Table name: cornercard_uploads
#
#  id          :bigint           not null, primary key
#  uploaded_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  person_id   :bigint           not null
#
# Indexes
#
#  index_cornercard_uploads_on_person_id  (person_id)
#
class CornercardUpload < ActiveRecord::Base
  belongs_to :person

  validates_by_schema

  scope :pending, -> { where(uploaded_at: nil) }
end
