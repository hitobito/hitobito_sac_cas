# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::PopoverCanceledReason
  delegate :action_button, :content_tag, :t, to: :@context

  def initialize(context, event)
    @context = context
    @event = event
  end

  def render
    content_tag(:div) { popover_content }
  end

  private

  def popover_content
    @context.render("events/popover_canceled_reason", entry: @event).to_s
  end
end
