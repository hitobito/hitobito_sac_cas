# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Nav1 = Data.define(
    :navision_id, # "No_",
    :membership_years, # "Vereinsmitgliederjahre",
    :first_name, # "First Name",
    :last_name, # "Surname",
    :address_care_of, # "Adresszusatz",
    :postbox, # "Postfach",
    :street_name, # "Street Name",
    :housenumber, # "Street No_",
    :country, # "Country_Region Code",
    :town, # "City",
    :zip_code, # "Post Code",
    :email, # "E-Mail",
    :phone, # "Phone No_",
    :birthday, # "Date of Birth",
    :gender, # "Geschlecht",
    :language, # "Language Code",
    :sac_remark_section_1, # "Sektionsinfo 1 Bemerkung",
    :sac_remark_section_2, # "Sektionsinfo 2 Bemerkung",
    :sac_remark_section_3, # "Sektionsinfo 3 Bemerkung",
    :sac_remark_section_4, # "Sektionsinfo 4 Bemerkung",
    :sac_remark_section_5, # "Sektionsinfo 5 Bemerkung",
    :sac_remark_national_office, # "Geschäftsstelle Bemerkung",
    :social_media, # "Social Media",
    :person_type, # "Personentyp",
    :member_kind, # "Mitgliederart",
    :beitragskategorie, # "Beitragskategorie",
    :die_alpen_physisch_opt_in, # "OPT_IN_Die_Alpen_physisch",
    :die_alpen_digital_opt_in, # "OPT_IN_Die_Alpen_digital",
    :fundraising_opt_in, # "OPT_IN_Fundraising",
    :sektionsbulletin_physisch_opt_in, # "OPT_IN_Sektionsbulletin_physisch",
    :sektionsbulletin_digital_opt_in, # "OPT_IN_Sektionsbulletin_digital",
    :die_alpen_physisch_opt_out, # "OPT_OUT_Die_Alpen_physisch",
    :die_alpen_digital_opt_out, # "OPT_OUT_Die_Alpen_digital",
    :termination_reason # "Austrittsgrund"
  )
end
