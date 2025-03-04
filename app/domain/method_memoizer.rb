# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module MethodMemoizer
  extend ActiveSupport::Concern

  NIL_VALUE = Object.new
  private_constant :NIL_VALUE

  class_methods do
    # Memoize the result of a method. The method is called once and the result is cached.
    # Subsequent calls will return the cached value.
    # It memoizes nil values as well and will not call the method again if the result was nil.
    def memoize_method(method_name)
      alias_method :"#{method_name}_without_memoization", method_name

      define_method method_name do |*args, &block|
        @memoized_values ||= {}
        value = @memoized_values[method_name] ||=
          send(:"#{method_name}_without_memoization", *args, &block) ||
          NIL_VALUE

        value unless value == NIL_VALUE
      end
    end
  end
end
