# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# Seed the newsletter with `seed_once` to avoid overwriting changed attributes.
sac_newsletter_list = MailingList.seed_once(
  :internal_key,
  internal_key: SacCas::MAILING_LIST_NEWSLETTER_INTERNAL_KEY,
  group_id: Group.root.id,
  name: "SAC/CAS Newsletter",
  subscribable_for: "configured",
  subscribable_mode: "opt_out"
).first || MailingList.find_by(internal_key: SacCas::MAILING_LIST_NEWSLETTER_INTERNAL_KEY)

sac_newsletter_subscription = Subscription.seed_once(
  :mailing_list_id,
  :subscriber_id,
  :subscriber_type,
  mailing_list_id: sac_newsletter_list.id,
  subscriber_id: Group.root.id,
  subscriber_type: Group.sti_name
).first || Subscription.find_by(mailing_list_id: sac_newsletter_list.id, subscriber_id: Group.root.id, subscriber_type: Group.sti_name)

RelatedRoleType.seed_once(
  :relation_id,
  :relation_type,
  :role_type,
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsMitglieder::Mitglied.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsMitglieder::Ehrenmitglied.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsMitglieder::Beguenstigt.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::AboTourenPortal::Abonnent.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::AboTourenPortal::Neuanmeldung.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::AboMagazin::Abonnent.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::AboMagazin::Neuanmeldung.sti_name},
  {relation_id: sac_newsletter_subscription.id, relation_type: Subscription.sti_name, role_type: Group::AboBasicLogin::BasicLogin.sti_name}
)

MountedAttribute.seed(
  :entry_id,
  :entry_type,
  :key,
  entry_id: Group.root.id,
  entry_type: "Group",
  key: "sac_newsletter_mailing_list_id",
  value: sac_newsletter_list.id.to_s
)

{
  MAILING_LIST_SAC_INSIDE_INTERNAL_KEY: "SAC Inside Newsletter",
  MAILING_LIST_TOURENLEITER_INTERNAL_KEY: "Tourenleiter Newsletter",
  MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY: "Die Alpen Papier",
  MAILING_LIST_DIE_ALPEN_DIGITAL_INTERNAL_KEY: "Die Alpen Digital",
  MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY: "Spendenaufrufe"
}.each do |key, name|
  MailingList.seed_once(
    :internal_key,
    internal_key: key,
    group_id: Group.root.id,
    name: name,
    subscribable_for: "configured",
    subscribable_mode: "opt_out"
  ).first || MailingList.find_by(internal_key: key)
end
