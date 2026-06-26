# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :report

  attribute :review, :string
  attribute :remarks, :string

  def initialize(report, attrs = {})
    @report = report
    super({review: report.review, remarks: report.remarks, **attrs})
  end

  def save
    report.update(review:, remarks:)
  end

  def tour_completed?
    [:ready, :closed].include?(report.event.state.to_sym)
  end
end
