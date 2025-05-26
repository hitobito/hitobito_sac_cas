# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacImports::CsvSource
  # !!! DO NOT CHANGE THE ORDER OF THE KEYS !!!
  # they must match the order of the columns in the CSV files
  Wso2 = Data.define(
    :um_id, # "UM_ID",
    :um_user_name, # "UM_USER_NAME",
    :wso2_legacy_password_hash, # "UM_USER_PASSWORD",
    :wso2_legacy_password_salt, # "UM_SALT_VALUE",
    :_um_changed_time, # "UM_CHANGED_TIME",
    :navision_id, # "ContactNo",
    :_name, # "Name",
    :gender, # "Anredecode",
    :first_name, # "Vorname",
    :last_name, # "FamilienName",
    :address_care_of, # "Addresszusatz",
    :address, # "Strasse",
    :postbox, # "Postfach",
    :town, # "Ort",
    :zip_code, # "PLZ",
    :_kanton, # "Kanton",
    :country, # "Land",
    :phone, # "TelefonMobil",
    :phone_business, # "TelefonG",
    :language, # "Korrespondenzsprache",
    :_benutzername, # "Benutzername",
    :email, # "Mail",
    :birthday, # "Geburtsdatum",
    :_vereinsmitgliedjahre, # "Vereinsmitgliedjahre",
    :_puk_code, # "PUK-Code",
    :_scim_id, # "scimId",
    :_profile_url, # "ProfileURL",
    :_merged_id, # "MergedID",
    :_department, # "Department",
    :_locality, # "Locality",
    :_account_lock, # "accountLock",
    :_account_state_disbaled_locked_unlocked, # "accountState_DISBALED_LOCKED_UNLOCKED",
    :email_verified, # "Email verified",
    :role_basiskonto, # "Basis Konto",
    :role_abonnent, # "Abonnent",
    :role_gratisabonnent, # "NAV_FSA2020FREE"
    :_rollen # "Rollen"
  )
end
