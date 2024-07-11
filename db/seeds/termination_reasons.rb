# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

TerminationReason.seed_once(:id, (1..8).map { {id: _1} })

TerminationReason::Translation.seed_once(:termination_reason_id, :locale,
  {termination_reason_id: 1, locale: "de", text: "Administrativ ausgetreten"},
  {termination_reason_id: 2, locale: "de", text: "Sektionswechsel"},
  {termination_reason_id: 3, locale: "de", text: "Gestorben"},
  {termination_reason_id: 4, locale: "de", text: "Weil ich nicht mehr aktiv in den Bergen bin"},
  {termination_reason_id: 5, locale: "de", text: "Aus Gesundheitsgründen"},
  {termination_reason_id: 6, locale: "de", text: "Altersbedingt"},
  {termination_reason_id: 7, locale: "de", text: "Weil es zu teuer ist"},
  {termination_reason_id: 8, locale: "de", text: "Weil ich mich nicht mehr identifizieren kann mit dem SAC"})
