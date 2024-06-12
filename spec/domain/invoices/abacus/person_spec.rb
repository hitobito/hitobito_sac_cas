# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Invoices::Abacus::Person do

  let(:person) { people(:mitglied) }
  let(:host) { 'https://abacus.example.com' }
  let(:mandant) { 1234 }
  let(:today) { Time.zone.today }

  subject { described_class.new(person) }

  before do
    person.update!(
      street: 'Belpstrasse',
      housenumber: '37',
      zip_code: '3007',
      town: 'Bern'
    )

    Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)

    stub_login_requests
  end

  it 'creates person in abacus' do
    stub_create_subject_request
    stub_create_address_request
    stub_create_communication_request
    stub_create_customer_request

    subject.transmit
    expect(person.abacus_subject_key).to eq(7)
  end

  it 'does nothing if attrs are unchanged' do
    person.abacus_subject_key = 7
    stub_get_subject_request

    subject.transmit
  end

  it 'creates address and customer if missing in abacus' do
    person.abacus_subject_key = 7
    stub_request(:get, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects(Id=7)?$expand=Addresses,Communications,Customers")
      .with(
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: {
        "@odata.context"=>"#{host}/api/entity/v1/mandants/#{mandant}/$metadata#Subjects(Addresses,Communications,Customers)/$entity",
        "@odata.etag"=>"W/\"2fdc485e7234e20bd9df6f58270f957ca5ca9d44507b20b9ffeac5dd58d29962\"",
        "Id"=>7, "FirstName"=>"Emma", "Name"=>"Hillary", "Title"=>"", "NameSupplement"=>"", "Language"=>"de",
        "ChangeInformation"=>{"CreatedBy"=>"223bfa10-514c-8a52-3378-55224270acf5", "CreatedOn"=>"2024-05-08T16:31:08.669+02:00",
                              "ChangedBy"=>"223bfa10-514c-8a52-3378-55224270acf5", "ChangedOn"=>"2024-05-08T16:31:08.669+02:00"},
        "Status"=>"Active", "Remark"=>"", "Key"=>"6c4b3c5c-91c2-c212-9538-a6a253da66c8", "RegisteredCompanyUid"=>"",
        "Type"=>"Person", "TaxIdSwitzerland"=>"", "TaxIdEuropeanUnion"=>"", "NogaCodeId"=>"", "DateOfBirth"=>nil,
        "Source"=>"", "NamePrefix"=>"", "NameSuffix"=>"", "Salutation"=>"Sehr geehrte Frau", "SalutationId"=>2,
        "UserFields"=>{"UserField1"=>""},
        "Addresses"=>[],
        "Communications"=>[{
          "@odata.etag"=>"W/\"f86b82e3bbf253df0eb29c2406cb3619d611d9300d1cd7daa8a3f0403857ad90\"",
          "Id"=>"ef83129d-470d-ef01-1ff3-001dd8b72ba4", "SubjectId"=>7, "LinkId"=>nil, "Type"=>"EMail",
          "Value"=>"emma.hillary@hitobito.example.com", "Standard"=>true, "Category"=>"Private", "Note"=>"", "Purpose"=>[]}],
        "Customers"=>[]}.to_json)
      stub_update_subject_request
      stub_create_address_request
      stub_update_communication_request("ef83129d-470d-ef01-1ff3-001dd8b72ba4")
      stub_create_customer_request

      subject.transmit
  end

  def stub_login_requests
    stub_request(:get, "#{host}/.well-known/openid-configuration")
      .to_return(status: 200, body: { token_endpoint: "#{host}/oauth/oauth2/v1/token" }.to_json )

    stub_request(:post, "#{host}/oauth/oauth2/v1/token")
      .with(
        body: {"grant_type"=>"client_credentials"},
        headers: {
        'Authorization'=>'Basic Og==',
        'Content-Type'=>'application/x-www-form-urlencoded',
        })
      .to_return(status: 200, body: { access_token: "eyJhbGciOi...", token_type:"Bearer", expires_in: 600 }.to_json)
  end

  def stub_create_subject_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects")
      .with(
        body: "{\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: "{\"Id\":7,\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}")
  end

  def stub_update_subject_request
    stub_request(:patch, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects(Id=7)")
      .with(
        body: "{\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: "{\"Id\":7,\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}")
  end

  def stub_create_address_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Addresses")
      .with(
        body: "{\"SubjectId\":7,\"Street\":\"Belpstrasse\",\"HouseNumber\":\"37\",\"PostCode\":\"3007\",\"City\":\"Bern\",\"CountryId\":\"CH\",\"ValidFrom\":\"#{today.strftime('%Y-%m-%d')}\"}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: "{}")
  end

  def stub_create_communication_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Communications")
      .with(
        body: "{\"SubjectId\":7,\"Type\":\"EMail\",\"Value\":\"e.hillary@hitobito.example.com\",\"Category\":\"Private\"}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: "{}")
  end

  def stub_update_communication_request(id)
    stub_request(:patch, "#{host}/api/entity/v1/mandants/#{mandant}/Communications(Id=#{id})")
      .with(
        body: "{\"SubjectId\":7,\"Type\":\"EMail\",\"Value\":\"e.hillary@hitobito.example.com\",\"Category\":\"Private\"}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: "{}")
  end

  def stub_create_customer_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Customers")
      .with(
        body: "{\"SubjectId\":7}",
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: "{}")
  end

  def stub_get_subject_request
    stub_request(:get, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects(Id=7)?$expand=Addresses,Communications,Customers")
      .with(
        headers: { 'Authorization'=>'Bearer eyJhbGciOi...' })
      .to_return(status: 200, body: {
        "@odata.context"=>"#{host}/api/entity/v1/mandants/#{mandant}/$metadata#Subjects(Addresses,Communications,Customers)/$entity",
        "@odata.etag"=>"W/\"2fdc485e7234e20bd9df6f58270f957ca5ca9d44507b20b9ffeac5dd58d29962\"",
        "Id"=>7, "FirstName"=>"Edmund", "Name"=>"Hillary", "Title"=>"", "NameSupplement"=>"", "Language"=>"de",
        "ChangeInformation"=>{"CreatedBy"=>"223bfa10-514c-8a52-3378-55224270acf5", "CreatedOn"=>"2024-05-08T16:31:08.669+02:00",
                              "ChangedBy"=>"223bfa10-514c-8a52-3378-55224270acf5", "ChangedOn"=>"2024-05-08T16:31:08.669+02:00"},
        "Status"=>"Active", "Remark"=>"", "Key"=>"6c4b3c5c-91c2-c212-9538-a6a253da66c8", "RegisteredCompanyUid"=>"",
        "Type"=>"Person", "TaxIdSwitzerland"=>"", "TaxIdEuropeanUnion"=>"", "NogaCodeId"=>"", "DateOfBirth"=>nil,
        "Source"=>"", "NamePrefix"=>"", "NameSuffix"=>"", "Salutation"=>"Sehr geehrte Frau", "SalutationId"=>2,
        "UserFields"=>{"UserField1"=>""},
        "Addresses"=>[{
          "@odata.etag"=>"W/\"ea2246585da92c0f2789e718fea4dfb29d56005e7d51c6e27cb5994b8838b5b0\"",
          "Id"=>"e65440b5-eb47-9482-21b0-a647a3972e0b", "SubjectId"=>7, "ValidFrom"=>"2024-05-08", "Street"=>"Belpstrasse",
          "HouseNumber"=>"37", "City"=>"Bern", "PostCode"=>"3007", "PostCodeSupplement"=>0, "CountryId"=>"CH", "State"=>"BE",
          "DwellingNumber"=>"", "MunicipalityCode"=>"351", "BuildingNumber"=>0, "AddressSupplement"=>"", "StreetSupplement"=>"",
          "PostOfficeBoxText"=>"", "PostOfficeBoxNumber"=>"", "OpenLocationCode"=>"", "Coordinates"=>nil}],
        "Communications"=>[{
          "@odata.etag"=>"W/\"f86b82e3bbf253df0eb29c2406cb3619d611d9300d1cd7daa8a3f0403857ad90\"",
          "Id"=>"ef83129d-470d-ef01-1ff3-001dd8b72ba4", "SubjectId"=>7, "LinkId"=>nil, "Type"=>"EMail",
          "Value"=>"e.hillary@hitobito.example.com", "Standard"=>true, "Category"=>"Private", "Note"=>"", "Purpose"=>[]}],
        "Customers"=>[{
          "@odata.etag"=>"W/\"2046f721492e448539278c6392cf450242ba80e3077f8b701dcbcfab8a06207c\"",
          "Id"=>7, "SubjectId"=>7, "DefaultCurrencyId"=>"CHF", "Status"=>"Active", "InactiveFrom"=>nil,
          "MultipleCurrenciesActive"=>false, "DivisionId"=>0, "DisabledForPayout"=>false, "ResponsiblePersonId"=>0,
          "CustomerCondition"=>{"PaymentConditionId"=>1, "DiscountToleranceDays"=>0, "DiscountTolerancePercent"=>0.0},
          "CustomerCreditLimit"=>{"CheckCreditRating"=>false},
          "CustomerReminder"=>{"ProcedureId"=>"NORM", "SubjectId"=>0, "ContactId"=>nil, "Mode"=>"Remind",
                               "ViewOrSendActive"=>false, "ViewWithNoReminder"=>false, "ViewBlocked"=>false, "BlockedUntil"=>nil,
                               "SendAccountStatement"=>false, "BlockedReasonId"=>0, "DispatchType"=>"Letter", "GracePeriodDays"=>0},
          "CustomerNote"=>[]}]}.to_json)
  end

end
