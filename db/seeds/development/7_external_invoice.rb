# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Person.all.find_each do |person|
  3.times do
    issued_at = Time.zone.today - rand(1..320).days
    ExternalInvoice.seed_once(
      :abacus_sales_order_key,
      person_id: person.id,
      type: "ExternalInvoice",
      total: rand(100..100),
      state: ExternalInvoice::STATES.sample,
      abacus_sales_order_key: rand(1000..10000),
      issued_at: issued_at,
      sent_at: issued_at + rand(1..30).days,
      year: issued_at.year
    )
  end
end
