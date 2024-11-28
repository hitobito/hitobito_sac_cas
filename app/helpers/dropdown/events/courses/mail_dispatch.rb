# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/HelperInstanceVariable

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
      add_mail_item(:leader_reminder)
      add_mail_item(:survey)
    end

    def add_mail_item(mail_type)
      if course.email_dispatch_possible?(mail_type)
        add_item(
          translate(".#{mail_type}"),
          template.group_event_mail_dispatch_path(group, course, mail_type: mail_type),
          method: :post,
          "data-confirm": translate(".confirmation")
        )
      end
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
