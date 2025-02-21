#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Synchronize::Mailchimp::Subscriber
  def first_name = with_company_fallback(:first_name)

  def last_name = with_company_fallback(:last_name, fallback: "Firma")

  def primary? = email == person.email

  def with_company_fallback(field, fallback: nil)
    value = person.send(field)
    return value unless person.company?

    value.presence || [person.company_name, fallback].compact_blank.first
  end
end
