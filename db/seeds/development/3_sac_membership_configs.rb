# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

SacMembershipConfig.seed_once(:valid_from,
                              valid_from: '2024',
                              sac_fee_adult: 10,
                              sac_fee_family: 10,
                              sac_fee_youth: 10,
                              entry_fee_adult: 10,
                              entry_fee_family: 10,
                              entry_fee_youth: 10,
                              hut_solidarity_fee_with_hut_adult: 10,
                              hut_solidarity_fee_with_hut_family: 10,
                              hut_solidarity_fee_with_hut_youth: 10,
                              hut_solidarity_fee_without_hut_adult: 10,
                              hut_solidarity_fee_without_hut_family: 10,
                              hut_solidarity_fee_without_hut_youth: 10,
                              magazine_fee_adult: 10,
                              magazine_fee_family: 10,
                              magazine_fee_youth: 10,
                              service_fee: 1,
                              magazine_postage_abroad: 10,
                              reduction_amount: 10,
                              reduction_required_membership_years: 50,
                              discount_date_1: '1.7.',
                              discount_percent_1: 50,
                              discount_date_2: '1.10.',
                              discount_percent_2: 100,
                              sac_fee_article_number: 'ZVB',
                              sac_entry_fee_article_number: 'ZVE',
                              hut_solidarity_fee_article_number: 'HUS',
                              magazine_fee_article_number: 'APG',
                              magazine_postage_abroad_article_number: 'PAL',
                              section_fee_article_number: 'SKB',
                              section_entry_fee_article_number: 'SKE',
                              section_bulletin_postage_abroad_article_number: 'PBU',
                              service_fee_article_number: '0',
                              balancing_payment_article_number: '0',
                              course_fee_article_number: 'KGB')
