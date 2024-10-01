# frozen_string_literal: true

if Rails.env.development?
  ActionView::Base.class_eval do
    alias_method :render_original, :render

    def render(options = {}, locals = {}, &block)
      partial_name = options.is_a?(Hash) ? options[:partial] || options[:layout] : options
      raw("<!--#{partial_name}-->") + render_original(options, locals, &block)
    end
  end
end
