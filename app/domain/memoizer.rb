# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memoizer
  NIL_VALUE = Object.new
  private_constant :NIL_VALUE

  private

  # Memoize the result of a block. The block is only called once and the result is cached.
  # Subsequent calls will return the cached value.
  # It memoizes nil values as well and will not call the block again if the result was nil.
  def memoized(&block)
    calling_method = caller_locations(1, 1)[0].to_s
    value = memoized_values[calling_method] ||= block.call || NIL_VALUE

    value unless value == NIL_VALUE
  end

  def memoized_values
    @memoized_values ||= {}
  end
end
