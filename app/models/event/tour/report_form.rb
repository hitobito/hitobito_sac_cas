# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :report

  def initialize(report, attrs = {})
    super(attrs)
    @report = report
  end

  def save
    true
  end
end
