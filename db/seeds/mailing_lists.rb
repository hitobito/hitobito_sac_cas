# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

def seed_list(internal_key, name, subscribable_mode: "opt_in", **opts)
  # Seed the newsletter with `seed_once` to avoid overwriting changed attributes.
  MailingList.seed_once(
    :internal_key,
    internal_key:,
    **opts.reverse_merge(
      group_id: Group.root.id,
      name:,
      subscribable_for: "configured",
      subscribable_mode:
    )
  ).first || MailingList.find_by(internal_key: internal_key)
end

def seed_subscription(list, *role_types, update: true)
  sub = Subscription.where(mailing_list_id: list.id, subscriber: Group.root).first_or_initialize
  if sub.role_types.sort != role_types.map(&:sti_name).sort && (sub.new_record? || update)
    sub.role_types = role_types
  end
  sub.save!
end

sac_newsletter_list = seed_list(
  SacCas::MAILING_LIST_SAC_NEWSLETTER_INTERNAL_KEY,
  "SAC/CAS Newsletter"
)

seed_subscription(sac_newsletter_list,
  Group::AboTourenPortal::Abonnent,
  Group::AboTourenPortal::Gratisabonnent,
  Group::AboMagazin::Abonnent,
  Group::AboMagazin::Gratisabonnent,
  Group::AboMagazin::Neuanmeldung,
  Group::AboBasicLogin::BasicLogin,
  Group::SektionsMitglieder::Mitglied,
  Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
  Group::SektionsNeuanmeldungenNv::Neuanmeldung)

die_alpen_paper_list = seed_list(
  SacCas::MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY,
  "Die Alpen - Zeitschrift des SAC",
  subscribable_mode: "opt_out",
  filter_chain: {"invoice_receiver" => {"stammsektion" => "true", "group_id" => Group.root.id}}
)

seed_subscription(die_alpen_paper_list,
  Group::SektionsMitglieder::Mitglied)

die_alpen_digital_list = seed_list(
  SacCas::MAILING_LIST_DIE_ALPEN_DIGITAL_INTERNAL_KEY,
  "Die Alpen - Digital"
)

seed_subscription(die_alpen_digital_list,
  Group::SektionsMitglieder::Mitglied,
  Group::AboMagazin::Abonnent,
  Group::AboMagazin::Gratisabonnent)

fundraising_list = seed_list(
  SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY,
  "Spendenaufrufe"
)

_sac_inside_list = seed_list(
  SacCas::MAILING_LIST_SAC_INSIDE_INTERNAL_KEY,
  "SAC-Inside"
)

tourenleiter_list = seed_list(
  SacCas::MAILING_LIST_TOURENLEITER_INTERNAL_KEY,
  "Tourenleiter-Newsletter"
)

seed_subscription(tourenleiter_list,
  Group::SektionsTourenUndKurse::Tourenleiter,
  update: false)

# Set the mailing list ID attrs on the root group.
Group.root.update!(
  sac_newsletter_mailing_list_id: sac_newsletter_list.id,
  sac_magazine_mailing_list_id: die_alpen_paper_list.id,
  sac_fundraising_mailing_list_id: fundraising_list.id
)
