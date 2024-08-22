# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::SubjectInterface do
  let(:person) { people(:mitglied) }
  let(:subject) { Invoices::Abacus::Subject.new(person) }
  let(:host) { "https://abacus.example.com" }
  let(:mandant) { 1234 }
  let(:today) { Time.zone.today }
  let(:interface) { described_class.new(abacus_client) }
  let(:abacus_client) { Invoices::Abacus::Client.new }

  before do
    person.update!(
      street: "Belpstrasse",
      housenumber: "37",
      zip_code: "3007",
      town: "Bern"
    )

    Invoices::Abacus::Config.instance_variable_set(:@config, {host: host, mandant: mandant}.stringify_keys)

    stub_login_requests
  end

  it "creates person in abacus" do
    stub_create_subject_request
    stub_create_address_request
    stub_create_communication_request
    stub_create_customer_request

    interface.transmit(subject)
    expect(person.abacus_subject_key).to eq(person.id)
  end

  it "does nothing if attrs are unchanged" do
    person.abacus_subject_key = person.id
    stub_get_subject_request

    interface.transmit(subject)
  end

  it "creates address and customer if missing in abacus" do
    person.abacus_subject_key = person.id
    stub_request(:get, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects(Id=#{person.id})?$expand=Addresses,Communications,Customers")
      .with(
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: {
        "@odata.context" => "#{host}/api/entity/v1/mandants/#{mandant}/$metadata#Subjects(Addresses,Communications,Customers)/$entity",
        "@odata.etag" => "W/\"2fdc485e7234e20bd9df6f58270f957ca5ca9d44507b20b9ffeac5dd58d29962\"",
        "Id" => person.id, "FirstName" => "Emma", "Name" => "Hillary", "Title" => "", "NameSupplement" => "", "Language" => "de",
        "ChangeInformation" => {"CreatedBy" => "223bfa10-514c-8a52-3378-55224270acf5", "CreatedOn" => "2024-05-08T16:31:08.669+02:00",
                                "ChangedBy" => "223bfa10-514c-8a52-3378-55224270acf5", "ChangedOn" => "2024-05-08T16:31:08.669+02:00"},
        "Status" => "Active", "Remark" => "", "Key" => "6c4b3c5c-91c2-c212-9538-a6a253da66c8", "RegisteredCompanyUid" => "",
        "Type" => "Person", "TaxIdSwitzerland" => "", "TaxIdEuropeanUnion" => "", "NogaCodeId" => "", "DateOfBirth" => nil,
        "Source" => "", "NamePrefix" => "", "NameSuffix" => "", "Salutation" => "Sehr geehrte Frau", "SalutationId" => 2,
        "UserFields" => {"UserField1" => ""},
        "Addresses" => [],
        "Communications" => [{
          "@odata.etag" => "W/\"f86b82e3bbf253df0eb29c2406cb3619d611d9300d1cd7daa8a3f0403857ad90\"",
          "Id" => "ef83129d-470d-ef01-1ff3-001dd8b72ba4", "SubjectId" => person.id, "LinkId" => nil, "Type" => "EMail",
          "Value" => "emma.hillary@hitobito.example.com", "Standard" => true, "Category" => "Private", "Note" => "", "Purpose" => []
        }],
        "Customers" => []
      }.to_json)
    stub_update_subject_request
    stub_create_address_request
    stub_update_communication_request("ef83129d-470d-ef01-1ff3-001dd8b72ba4")
    stub_create_customer_request

    interface.transmit(subject)
  end

  context "#batch_transmit" do
    let(:subjects) { people(:mitglied, :familienmitglied, :familienmitglied_kind).map { |p| Invoices::Abacus::Subject.new(p) } }

    before do
      Person.where(zip_code: nil).update_all(zip_code: 3600, street: nil, housenumber: nil, town: "Thun", country: nil)
      allow(abacus_client).to receive(:generate_batch_boundary).and_return("batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649")
    end

    it "transmits batch of non-exising people people to abacus" do
      stub_fetch_batch_missing_request
      stub_create_batch_subject_request
      stub_create_batch_associations_request

      interface.transmit_batch(subjects)

      subjects.each do |subject|
        expect(subject.entity.abacus_subject_key).to eq(subject.entity.id)
      end
    end

    it "transmits batch of already existing people to abacus" do
      stub_fetch_batch_existing_request
      stub_update_batch_request

      interface.transmit_batch(subjects)

      subjects.each do |subject|
        expect(subject.entity.abacus_subject_key).to eq(subject.entity.id)
      end
    end
  end

  def stub_login_requests
    stub_request(:get, "#{host}/.well-known/openid-configuration")
      .to_return(status: 200, body: {token_endpoint: "#{host}/oauth/oauth2/v1/token"}.to_json)

    stub_request(:post, "#{host}/oauth/oauth2/v1/token")
      .with(
        body: {"grant_type" => "client_credentials"},
        headers: {
          "Authorization" => "Basic Og==",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      )
      .to_return(status: 200, body: {access_token: "eyJhbGciOi...", token_type: "Bearer", expires_in: 600}.to_json)
  end

  def stub_create_subject_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects")
      .with(
        body: "{\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2,\"Id\":#{person.id}}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{\"Id\":#{person.id},\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}")
  end

  def stub_update_subject_request
    stub_request(:patch, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects(Id=#{person.id})")
      .with(
        body: "{\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{\"Id\":#{person.id},\"Name\":\"Hillary\",\"FirstName\":\"Edmund\",\"Language\":\"de\",\"SalutationId\":2}")
  end

  def stub_create_address_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Addresses")
      .with(
        body: "{\"SubjectId\":#{person.id},\"Street\":\"Belpstrasse\",\"HouseNumber\":\"37\",\"PostCode\":\"3007\",\"City\":\"Bern\",\"CountryId\":\"CH\",\"ValidFrom\":\"#{today.strftime("%Y-%m-%d")}\"}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end

  def stub_create_communication_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Communications")
      .with(
        body: "{\"SubjectId\":#{person.id},\"Type\":\"EMail\",\"Value\":\"e.hillary@hitobito.example.com\",\"Category\":\"Private\"}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end

  def stub_update_communication_request(id)
    stub_request(:patch, "#{host}/api/entity/v1/mandants/#{mandant}/Communications(Id=#{id})")
      .with(
        body: "{\"SubjectId\":#{person.id},\"Type\":\"EMail\",\"Value\":\"e.hillary@hitobito.example.com\",\"Category\":\"Private\"}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end

  def stub_create_customer_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/#{mandant}/Customers")
      .with(
        body: "{\"SubjectId\":#{person.id}}",
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: "{}")
  end

  def stub_get_subject_request
    stub_request(:get, "#{host}/api/entity/v1/mandants/#{mandant}/Subjects(Id=#{person.id})?$expand=Addresses,Communications,Customers")
      .with(
        headers: {"Authorization" => "Bearer eyJhbGciOi..."}
      )
      .to_return(status: 200, body: get_subject_response)
  end

  def stub_fetch_batch_missing_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: fetch_batch_body,
        headers: {
          "Authorization" => "Bearer eyJhbGciOi...",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: fetch_batch_missing_response,
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )
  end

  def stub_fetch_batch_existing_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: fetch_batch_body,
        headers: {
          "Authorization" => "Bearer eyJhbGciOi...",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: fetch_batch_existing_response,
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )
  end

  def stub_create_batch_subject_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: create_batch_subjects_body,
        headers: {
          "Authorization" => "Bearer eyJhbGciOi...",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: create_batch_subjects_response,
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )
  end

  def stub_create_batch_associations_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: create_batch_associations_body,
        headers: {
          "Authorization" => "Bearer eyJhbGciOi...",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: "",
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )
  end

  def stub_update_batch_request
    stub_request(:post, "#{host}/api/entity/v1/mandants/1234/$batch")
      .with(
        body: update_batch_body,
        headers: {
          "Authorization" => "Bearer eyJhbGciOi...",
          "Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649"
        }
      )
      .to_return(
        status: 202,
        body: "",
        headers: {"Content-Type" => "multipart/mixed;boundary=batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf"}
      )
  end

  def get_subject_response
    {
      "@odata.context" => "#{host}/api/entity/v1/mandants/#{mandant}/$metadata#Subjects(Addresses,Communications,Customers)/$entity",
      "@odata.etag" => "W/\"2fdc485e7234e20bd9df6f58270f957ca5ca9d44507b20b9ffeac5dd58d29962\"",
      "Id" => person.id, "FirstName" => "Edmund", "Name" => "Hillary", "Title" => "", "NameSupplement" => "", "Language" => "de",
      "ChangeInformation" => {"CreatedBy" => "223bfa10-514c-8a52-3378-55224270acf5", "CreatedOn" => "2024-05-08T16:31:08.669+02:00",
                              "ChangedBy" => "223bfa10-514c-8a52-3378-55224270acf5", "ChangedOn" => "2024-05-08T16:31:08.669+02:00"},
      "Status" => "Active", "Remark" => "", "Key" => "6c4b3c5c-91c2-c212-9538-a6a253da66c8", "RegisteredCompanyUid" => "",
      "Type" => "Person", "TaxIdSwitzerland" => "", "TaxIdEuropeanUnion" => "", "NogaCodeId" => "", "DateOfBirth" => nil,
      "Source" => "", "NamePrefix" => "", "NameSuffix" => "", "Salutation" => "Sehr geehrte Frau", "SalutationId" => 2,
      "UserFields" => {"UserField1" => ""},
      "Addresses" => [{
        "@odata.etag" => "W/\"ea2246585da92c0f2789e718fea4dfb29d56005e7d51c6e27cb5994b8838b5b0\"",
        "Id" => "e65440b5-eb47-9482-21b0-a647a3972e0b", "SubjectId" => person.id, "ValidFrom" => "2024-05-08", "Street" => "Belpstrasse",
        "HouseNumber" => "37", "City" => "Bern", "PostCode" => "3007", "PostCodeSupplement" => 0, "CountryId" => "CH", "State" => "BE",
        "DwellingNumber" => "", "MunicipalityCode" => "351", "BuildingNumber" => 0, "AddressSupplement" => "", "StreetSupplement" => "",
        "PostOfficeBoxText" => "", "PostOfficeBoxNumber" => "", "OpenLocationCode" => "", "Coordinates" => nil
      }],
      "Communications" => [{
        "@odata.etag" => "W/\"f86b82e3bbf253df0eb29c2406cb3619d611d9300d1cd7daa8a3f0403857ad90\"",
        "Id" => "ef83129d-470d-ef01-1ff3-001dd8b72ba4", "SubjectId" => person.id, "LinkId" => nil, "Type" => "EMail",
        "Value" => "e.hillary@hitobito.example.com", "Standard" => true, "Category" => "Private", "Note" => "", "Purpose" => []
      }],
      "Customers" => [{
        "@odata.etag" => "W/\"2046f721492e448539278c6392cf450242ba80e3077f8b701dcbcfab8a06207c\"",
        "Id" => person.id, "SubjectId" => person.id, "DefaultCurrencyId" => "CHF", "Status" => "Active", "InactiveFrom" => nil,
        "MultipleCurrenciesActive" => false, "DivisionId" => 0, "DisabledForPayout" => false, "ResponsiblePersonId" => 0,
        "CustomerCondition" => {"PaymentConditionId" => 1, "DiscountToleranceDays" => 0, "DiscountTolerancePercent" => 0.0},
        "CustomerCreditLimit" => {"CheckCreditRating" => false},
        "CustomerReminder" => {"ProcedureId" => "NORM", "SubjectId" => 0, "ContactId" => nil, "Mode" => "Remind",
                               "ViewOrSendActive" => false, "ViewWithNoReminder" => false, "ViewBlocked" => false, "BlockedUntil" => nil,
                               "SendAccountStatement" => false, "BlockedReasonId" => 0, "DispatchType" => "Letter", "GracePeriodDays" => 0},
        "CustomerNote" => []
      }]
    }.to_json
  end

  def fetch_batch_body
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      GET Subjects(Id=600001)?%24expand=Addresses%2CCommunications%2CCustomers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      \r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      GET Subjects(Id=600002)?%24expand=Addresses%2CCommunications%2CCustomers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      \r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      GET Subjects(Id=600004)?%24expand=Addresses%2CCommunications%2CCustomers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      \r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end

  def fetch_batch_missing_response
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 404 Not Found\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 404 Not Found\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 404 Not Found\r
      Content-Type: application/json\r
      Accept: application/json\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end

  def fetch_batch_existing_response
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 200 OK\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Hillary","FirstName":"Edmund","Language":"de","SalutationId":2,"Id":600001,\r
       "Addresses":[{"Id":"e65440b","SubjectId":600001,"ValidFrom":"2024-05-08","Street":"Belpstrasse","HouseNumber":"37","City":"Bern","PostCode":"3007","CountryId":"CH","State":"BE"}],\r
       "Communications":[{"Id":"ef83129d","SubjectId":600001,"Type":"EMail","Value":"e.hillary@hitobito.example.com","Category":"Private"}],
       "Customers":[{"Id":600001,"SubjectId":600001,"Status":"Active"}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 200 OK\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Tenzing","Language":"de","SalutationId":2,"Id":600002,\r
       "Addresses":[{"Id":"e65440b","SubjectId":600002,"ValidFrom":"2024-05-08","Street":"Hauptstrasse","HouseNumber":"1","City":"Thun","PostCode":"3600","CountryId":"CH","State":"BE"}],\r
       "Communications":[{"Id":"ef83129d","SubjectId":600002,"Type":"EMail","Value":"tenzing@hitobito.example.com","Category":"Private"}],
       "Customers":[{"Id":600002,"SubjectId":600002,"Status":"Active"}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 200 OK\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Nima","Language":"de","SalutationId":1,"Id":600004,\r
       "Addresses":[{"Id":"e65440b","SubjectId":600004,"ValidFrom":"2024-05-08","Street":"","HouseNumber":"","City":"Thun","PostCode":"3600","CountryId":"CH","State":"BE"}],\r
       "Communications":[{"Id":"ef83129d","SubjectId":600004,"Type":"EMail","Value":"n.norgay@hitobito.example.com","Category":"Private"}]}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end

  def create_batch_subjects_body
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Hillary","FirstName":"Edmund","Language":"de","SalutationId":2,"Id":600001}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Tenzing","Language":"de","SalutationId":2,"Id":600002}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Subjects HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Nima","Language":"de","SalutationId":2,"Id":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end

  def create_batch_subjects_response
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Hillary","FirstName":"Edmund","Language":"de","SalutationId":2,"Id":600001}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Tenzing","Language":"de","SalutationId":2,"Id":600002}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      HTTP/1.1 201 Created\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Nima","Language":"de","SalutationId":2,"Id":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-asdasdfasdf--\r
    HTTP
  end

  def create_batch_associations_body
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600001,"Street":"Belpstrasse","HouseNumber":"37","PostCode":"3007","City":"Bern","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600001,"Type":"EMail","Value":"e.hillary@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600001}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002,"Type":"EMail","Value":"t.norgay@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Communications HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004,"Type":"EMail","Value":"n.norgay@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end

  def update_batch_body
    <<~HTTP
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Addresses HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002,"Street":"","HouseNumber":"","PostCode":"3600","City":"Thun","CountryId":"CH","ValidFrom":"#{today}"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      PATCH Communications(Id=ef83129d) HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600002,"Type":"EMail","Value":"t.norgay@hitobito.example.com","Category":"Private"}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      PATCH Subjects(Id=600004) HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"Name":"Norgay","FirstName":"Nima","Language":"de","SalutationId":2}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649\r
      Content-Type: application/http\r
      Content-Transfer-Encoding: binary\r
      \r
      POST Customers HTTP/1.1\r
      Content-Type: application/json\r
      Accept: application/json\r
      \r
      {"SubjectId":600004}\r
      --batch-boundary-3f8b206b-4aec-4616-bd28-c1ccbe572649--\r
    HTTP
  end
end
