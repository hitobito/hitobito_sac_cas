# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleHelper
  def format_person_sac_family_main_person(person)
    main_person = person.sac_family.main_person

    if person == main_person
      f(true)
    elsif main_person.nil?
      ti('.unknown')
    elsif can?(:read, main_person)
      link_to(main_person.to_s, main_person)
    else
      main_person.to_s
    end
  end

  def people_sac_membership_qr_code(person, html_options = {})
    verification_qr_code = People::Membership::VerificationQrCode.new(person)
    qr_code = verification_qr_code.generate
    verify_url = verification_qr_code.verify_url
    qr_code_png = qr_code.as_png(size: 220)
    qr_code_data = Base64.encode64(qr_code_png.to_blob)
    default_options = { alt: 'QR Code', size: '220x220' }
    options = default_options.merge(html_options)
    link_to(verify_url, target: '_blank', rel: 'noopener') do
      image_tag("data:image/png;base64,#{qr_code_data}", options)
    end
  end

  def people_sac_membership_download_dropdown(person)
    Dropdown::People::SacMembership::Download.new(self, person).to_s
  end
end
