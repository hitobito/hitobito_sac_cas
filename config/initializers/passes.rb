# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Rails.application.config.to_prepare do
  Passes::TemplateRegistry.register(Settings.passes.legacy_verify_pass_definition_key,
    pdf_class: SacCas::Export::Pdf::Passes::Membership,
    pass_view_partial: Settings.passes.legacy_verify_pass_definition_key,
    wallet_data_provider: SacCas::Passes::MembershipDataProvider)
end
