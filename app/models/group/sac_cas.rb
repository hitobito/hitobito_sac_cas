# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SacCas < ::Group

  self.layer = true
  self.event_types = [Event::Course]

  children Group::Geschaeftsstelle,
           Group::Sektion,
           Group::ExterneKontakte,
           Group::Abonnenten

  mounted_attr :sac_newsletter_mailing_list_id, :integer

  validate :assert_sac_newsletter_mailing_list_id

  private

  def assert_sac_newsletter_mailing_list_id
    return unless sac_newsletter_mailing_list_id
    ids = mailing_lists.pluck(:id)

    if ids.exclude?(sac_newsletter_mailing_list_id.to_i)
      errors.add(:sac_newsletter_mailing_list_id, :inclusion)
    end
  end
end
