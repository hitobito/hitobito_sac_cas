# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfRegistrationController
  extend ActiveSupport::Concern

  included do
    before_save :add_newsletter_label
  end

  def add_newsletter_label
    return unless true?(params[:newsletter])
    entry.person.tag_list.add('Newsletter')
  end
end
