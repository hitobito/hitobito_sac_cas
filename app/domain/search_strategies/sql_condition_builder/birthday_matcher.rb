# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SearchStrategies::SqlConditionBuilder
  class BirthdayMatcher < Matcher
    DATE_FORMAT = "%d.%m.%Y"

    def applies?
      date_string.present?
    end

    private

    def column
      super.then do |c|
        Arel::Nodes::NamedFunction.new("DATE_FORMAT", [c, date_format])
      end
    end

    def date_format
      Arel::Nodes::SqlLiteral.new("'#{DATE_FORMAT}'")
    end

    def quoted_word
      Arel::Nodes::Quoted.new("%#{date_string}%")
    end

    def date_string
      numbers = @word.split(".").map(&:to_i)
      return unless numbers.all?(&:positive?)

      numbers.map do |number|
        (number < 10) ? "0#{number}" : number
      end.join(".")
    end
  end
end
