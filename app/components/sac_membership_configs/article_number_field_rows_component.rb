# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacMembershipConfigs
  class ArticleNumberFieldRowsComponent < FieldRowsComponent

    def initialize(form:, attrs: [])
      super
      @attrs = [:sac_fee_article_number,
                :sac_entry_fee_article_number,
                :hut_solidarity_fee_article_number,
                :magazine_fee_article_number,
                :section_bulletin_postage_abroad_article_number,
                :service_fee_article_number,
                :balancing_payment_article_number,
                :course_fee_article_number]
    end

  end
end
