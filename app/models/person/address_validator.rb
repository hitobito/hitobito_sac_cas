# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Person::AddressValidator < ActiveModel::Validator
  RELAXED_ZIP_CODES = [
    # rubocop:todo Layout/LineLength
    1148, 1260, 1413, 1413, 1792, 1805, 1882, 1896, 1929, 1945, 1946, 1948, 1983, 1996, 2722, 2732, 2735,
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    2740, 2805, 3863, 3907, 3925, 3956, 3961, 3961, 4242, 6523, 6532, 6540, 6558, 6562, 6563, 6577, 6579,
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    6594, 6611, 6632, 6632, 6636, 6647, 6662, 6670, 6672, 6673, 6678, 6682, 6690, 6702, 6720, 6760, 6773,
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    6775, 6802, 6817, 6837, 6839, 6863, 6865, 6875, 6930, 6937, 6938, 6944, 6945, 6951, 6953, 6954, 6959,
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    6964, 6964, 6965, 6966, 6967, 6968, 6980, 6981, 6981, 6986, 6991, 6992, 6994, 7242, 7422, 7516, 7542,
    # rubocop:enable Layout/LineLength
    7543, 7545, 7546, 7553, 7557, 7602, 7603, 7606, 7608, 8732
  ]

  def validate(record)
    # rubocop:todo Layout/LineLength
    if record.street.blank? && record.postbox.blank? && RELAXED_ZIP_CODES.exclude?(record.zip_code.to_i)
      # rubocop:enable Layout/LineLength
      record.errors.add(:street, :blank)
    end
  end
end
