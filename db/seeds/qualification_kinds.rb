# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

unless QualificationKind.exists?
  QualificationKind.seed_once(:id,
    {id: 1, tourenchef_may_edit: true},
    {id: 2, tourenchef_may_edit: true},
    {id: 3, tourenchef_may_edit: true},
    {id: 4, tourenchef_may_edit: true},
    {id: 5, tourenchef_may_edit: true},
    {id: 6, tourenchef_may_edit: true},
    {id: 7, tourenchef_may_edit: true},
    {id: 8, tourenchef_may_edit: true},
    {id: 9, tourenchef_may_edit: false},
    {id: 10, tourenchef_may_edit: false},
    {id: 11, tourenchef_may_edit: true},
    {id: 12, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 13, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 14, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 15, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 16, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 17, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 18, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 19, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 20, tourenchef_may_edit: false},
    {id: 21, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 22, tourenchef_may_edit: false, validity: 6, reactivateable: 4, required_training_days: 3},
    {id: 23, tourenchef_may_edit: true},
    {id: 24, tourenchef_may_edit: true},
    {id: 25, tourenchef_may_edit: true},
    {id: 26, tourenchef_may_edit: true},
    {id: 27, tourenchef_may_edit: true},
    {id: 28, tourenchef_may_edit: true},
    {id: 29, tourenchef_may_edit: true})

  QualificationKind::Translation.seed_once(:qualification_kind_id, :locale,
    # rubocop:todo Layout/LineLength
    {qualification_kind_id: 1, locale: "de", label: "Bergführer Aspirant/in"}, # unusual gendering required for import
    # rubocop:enable Layout/LineLength
    {qualification_kind_id: 2, locale: "de", label: "Bergführer*in SBV"},
    {qualification_kind_id: 3, locale: "de", label: "Bikeleiter*in"},
    {qualification_kind_id: 4, locale: "de", label: "Diverse Leiter*in"},
    {qualification_kind_id: 5, locale: "de", label: "Fitnessleiter*in"},
    {qualification_kind_id: 6, locale: "de", label: "Gleitschirmleiter*in"},
    {qualification_kind_id: 7, locale: "de", label: "Höhlenleiter*in"},
    {qualification_kind_id: 8, locale: "de", label: "Kletterlehrer*in SBV"},
    {qualification_kind_id: 9, locale: "de", label: "Leiter*in Familienbergsteigen"},
    {qualification_kind_id: 10, locale: "de", label: "Leiter*in Kinderbergsteigen"},
    {qualification_kind_id: 11, locale: "de", label: "SAC  Aspirant*in - Tourenleiter*in"},
    {qualification_kind_id: 12, locale: "de", label: "SAC Tourenleiter*in 1 Sommer"},
    {qualification_kind_id: 13, locale: "de", label: "SAC Tourenleiter*in 1 Sommer Senioren"},
    {qualification_kind_id: 14, locale: "de", label: "SAC Tourenleiter*in 1 Winter"},
    {qualification_kind_id: 15, locale: "de", label: "SAC Tourenleiter*in 1 Winter Schneeschuhe"},
    {qualification_kind_id: 16, locale: "de", label: "SAC Tourenleiter*in 1 Winter Senioren"},
    {qualification_kind_id: 17, locale: "de", label: "SAC Tourenleiter*in 2 Sommer"},
    {qualification_kind_id: 18, locale: "de", label: "SAC Tourenleiter*in 2 Winter"},
    {qualification_kind_id: 19, locale: "de", label: "SAC Tourenleiter*in Alpinwandern"},
    {qualification_kind_id: 20, locale: "de", label: "SAC Tourenleiter*in Bergwandern"},
    # rubocop:todo Layout/LineLength
    {qualification_kind_id: 21, locale: "de", label: "SAC Tournleiter*in Mountainbike"}, # Typo required for import
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {qualification_kind_id: 22, locale: "de", label: "SAC Tourenleiter*in Sportklettern *"}, # * required for import
    # rubocop:enable Layout/LineLength
    {qualification_kind_id: 23, locale: "de", label: "Schneeschuhleiter*in bis WT4"},
    {qualification_kind_id: 24, locale: "de", label: "Schneesportlehrer*in"},
    {qualification_kind_id: 25, locale: "de", label: "Swiss Cycling MTB Guide"},
    {qualification_kind_id: 26, locale: "de", label: "Walkingleiter*in"},
    {qualification_kind_id: 27, locale: "de", label: "Wanderleiter*in bis T2"},
    {qualification_kind_id: 28, locale: "de", label: "Wanderleiter*in bis T3"},
    {qualification_kind_id: 29, locale: "de", label: "Wanderleiter*in bis T4"})
end
