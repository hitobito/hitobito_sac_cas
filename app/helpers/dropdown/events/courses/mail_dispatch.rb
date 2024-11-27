# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown::Events::Courses
  class MailDispatch < ::Dropdown::Base
    attr_reader :course, :template, :group

    delegate :t, to: :template

    def initialize(template, course, group)
      @course = course
      @group = group
      @template = template
      super(template, translate(".title"), :envelope)
      init_items
    end

    private

    def init_items
      add_item(translate(".finish_preparation"), template.group_event_mail_dispatch_path(group, course), method: :post, "data-confirm": translate(".confirmation"))
      add_item(translate(".survey"), template.group_event_mail_dispatch_path(group, course), method: :post, "data-confirm": translate(".confirmation"))
    end
  end
end
