# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Person::AddressValidator do
  shared_examples "address validator" do |record:|
    let(:object) { record.is_a?(Proc) ? record.call : record }

    it "validates street presence if postbox is blank" do
      object.street = nil
      object.postbox = nil
      object.valid?
      expect(object.errors.attribute_names).to include(:street)
    end

    it "allows blank street if postbox is set" do
      object.street = nil
      object.postbox = "test"
      object.valid?
      expect(object.errors.attribute_names).not_to include(:street)
    end

    it "allows blank street for relaxed zip_code" do
      relaxed_zip_code = [
        1148, 1260, 1413, 1413, 1792, 1805, 1882, 1896, 1929, 1945, 1946, 1948, 1983, 1996, 2722, 2732, 2735,
        2740, 2805, 3863, 3907, 3925, 3956, 3961, 3961, 4242, 6523, 6532, 6540, 6558, 6562, 6563, 6577, 6579,
        6594, 6611, 6632, 6632, 6636, 6647, 6662, 6670, 6672, 6673, 6678, 6682, 6690, 6702, 6720, 6760, 6773,
        6775, 6802, 6817, 6837, 6839, 6863, 6865, 6875, 6930, 6937, 6938, 6944, 6945, 6951, 6953, 6954, 6959,
        6964, 6964, 6965, 6966, 6967, 6968, 6980, 6981, 6981, 6986, 6991, 6992, 6994, 7242, 7422, 7516, 7542,
        7543, 7545, 7546, 7553, 7557, 7602, 7603, 7606, 7608, 8732
      ].sample
      object.street = nil
      object.zip_code = relaxed_zip_code
      object.valid?
      expect(object.errors.attribute_names).not_to include(:street)
    end

    it "allows blank housenumber" do
      object.housenumber = nil
      object.valid?
      expect(object.errors.attribute_names).not_to include(:street)
    end
  end

  it_behaves_like "address validator", record: -> { Person.find(600_001) } # mitglied
  # TBD check wizard models als well?
end
