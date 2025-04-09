# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

root = Group.root

magazine_list = MailingList.seed(:name, :group_id, {
  name: "Die Alpen (physisch)",
  group_id: root.id
}).first

unless magazine_list.subscriptions.exists?
  magazine_list.subscriptions.create!(subscriber: root, role_types: [Group::SektionsMitglieder::Mitglied])
end

Group::Sektion.all.find_each do |sektion|
  sektion_bulletin = MailingList.seed(:name, :group_id, :internal_key, {
    name: "Sektionsbulletin physisch",
    group_id: sektion.id,
    internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY
  }).first

  sektion_bulletin.subscriptions.create!(subscriber: sektion, role_types: [Group::SektionsMitglieder::Mitglied])
end
