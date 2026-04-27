# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class HoursDuration
  attr_reader :total_minutes

  class << self
    def parse(value)
      if value.is_a?(Integer) || value.match(/^\d{1,2}$/)
        from_integer_hours(value)
      elsif value.include?(":")
        from_string_format(value)
      elsif value.include?(".")
        from_decimal_hours(value)
      elsif value.match?(/^\d{3,4}$/)
        from_military_time(value)
      else
        new(value)
      end
    end

    def from_string_format(value)
      # Handle "hh:mm" or "h:m"
      hours, minutes = value.split(":").map(&:to_i)
      new((hours * 60) + (minutes || 0))
    end

    def from_decimal_hours(value)
      # Handle "hh.mm" as decimal hours (e.g., 1.5 = 90 mins)
      new((value.to_f * 60).round)
    end

    def from_military_time(value)
      # Handle "hhmm" or "hmm" (e.g., 0130 or 130)
      # We take the last two digits as minutes, the rest as hours
      hours = value[0...-2].to_i
      minutes = value[-2..].to_i
      new((hours * 60) + minutes)
    end

    def from_integer_hours(value)
      # Handle "hh" or "h"
      new(value.to_i * 60)
    end
  end

  def initialize(minutes)
    @total_minutes = minutes
  end

  def hours = total_minutes.to_i.divmod(60).first

  def minutes = total_minutes&.to_i&.divmod(60)&.last

  def to_s
    return total_minutes unless valid?
    return nil unless total_minutes

    format("%d:%02d", hours, minutes)
  end

  def valid?
    total_minutes.nil? || (total_minutes.is_a?(Integer) && total_minutes.positive?)
  end
end
