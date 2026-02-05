# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module MethodMemoizer
  extend ActiveSupport::Concern

  class_methods do
    # Memoize the result of a method. The method is called once per unique set of arguments
    # and the result is cached. Subsequent calls with the same arguments will return the cached
    # value.
    # It memoizes nil and false values as well and will not call the method again if the result
    # was nil or false.
    # Note: Blocks are supported but not memoized by their content - only by their source location.
    def memoize_method(method_name)
      alias_method :"#{method_name}_without_memoization", method_name

      define_method method_name do |*args, &block|
        @memoized_values ||= {}
        cache_key = [method_name, args, block&.source_location].freeze

        return @memoized_values[cache_key] if @memoized_values.key?(cache_key)

        @memoized_values[cache_key] = send(:"#{method_name}_without_memoization", *args, &block)
      end
    end
  end
end
