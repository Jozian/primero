# frozen_string_literal: true

require 'rails_helper'

describe Api::V2::PrimeroConfigurationsController, type: :request do
  include ActiveJob::TestHelper

  before(:each) do
    clean_data(
      PrimeroConfiguration, FormSection, Lookup, Agency, Role, UserGroup, Report, ContactInformation, PrimeroModule
    )
    @form1 = FormSection.create!(unique_id: 'A', name: 'A', parent_form: 'case', form_group_id: 'm')
    @lookup1 = Lookup.create!(unique_id: 'lookup1', name: 'lookup1')
    @agency1 = Agency.create!(name: 'irc', agency_code: '12345')
    permissions = [Permission.new(resource: Permission::CASE, actions: [Permission::READ])]
    module1 = PrimeroModule.create!(
      unique_id: 'primeromodule-cp-a', name: 'CPA', associated_record_types: %w[case], form_sections: [@form1]
    )
    @role1 = Role.create!(name: 'Role', permissions: permissions)
    @user_group1 = UserGroup.create!(name: 'Test Group')
    @report1 = Report.create!(
      record_type: 'case', name_en: 'Test', unique_id: 'report-test',
      aggregate_by: %w[a b], module_id: module1.unique_id
    )
    @contact_info = ContactInformation.create!(name: 'test')
    @configuration = PrimeroConfiguration.current
    @configuration.save!
  end

  let(:json) { JSON.parse(response.body) }
  let(:correct_permissions) do
    [Permission.new(resource: Permission::CONFIGURATION, actions: [Permission::MANAGE])]
  end

  after(:all) do
    clean_data(
      PrimeroConfiguration, FormSection, Lookup, Agency, Role, UserGroup, Report, ContactInformation, PrimeroModule, SystemSettings
    )
  end

  describe 'GET /api/v2/configurations' do
    it 'provides a paginated list of configurations' do
      login_for_test(permissions: correct_permissions)
      get '/api/v2/configurations'

      expect(response).to have_http_status(200)
      expect(json['data'].count).to eq(1)
      expect(json['data'][0]['version']).to eq(@configuration.version)
      expect(json['metadata']['total']).to eq(1)
      expect(json['metadata']['per']).to eq(20)
      expect(json['metadata']['page']).to eq(1)
    end

    it 'returns 403 if user is not authorized to access' do
      login_for_test
      get '/api/v2/configurations'

      expect(response).to have_http_status(403)
      expect(json['errors'][0]['resource']).to eq('/api/v2/configurations')
      expect(json['errors'][0]['message']).to eq('Forbidden')
    end
  end

  describe 'GET /api/v2/configurations/:id' do
    it 'fetches the configuration description with code 200' do
      login_for_test(permissions: correct_permissions)
      get "/api/v2/configurations/#{@configuration.id}"

      expect(response).to have_http_status(200)
      expect(json['data']['version']).to eq(@configuration.version)
    end
  end

  describe 'POST /api/v2/configurations' do
    it 'creates a configuration record from the current configuration state' do
      params = { data: { name: 'Test' } }

      login_for_test(permissions: correct_permissions)
      post '/api/v2/configurations', params: params

      expect(response).to have_http_status(200)
      expect(json['data']['name']).to eq('Test')
      expect(json['data'].compact.keys).to match_array(%w[id name version created_on created_by])
      expect(json['data']['created_by']).to eq(fake_user_name)
    end

    it 'returns 403 if user is not authorized to create' do
      params = { name: 'Test' }

      login_for_test
      post '/api/v2/configurations', params: params

      expect(response).to have_http_status(403)
    end
  end

  describe 'PATCH /api/v2/configurations/:id' do
    before do
      allow_any_instance_of(ApplyConfigurationJob).to receive(:perform)
    end

    it 'launches the apply configuration job if the parameter apply_now is set' do
      params = { data: { apply_now: true } }
      login_for_test(permissions: correct_permissions)
      patch "/api/v2/configurations/#{@configuration.id}", params: params

      expect(response).to have_http_status(200)
      expect(ApplyConfigurationJob).to have_been_enqueued
        .with(json['data']['id'], fake_user.id)
    end

    it 'does not launch the apply configuration job if the parameter apply_now is not set' do
      params = { data: { name: 'Test' } }
      login_for_test(permissions: correct_permissions)
      patch "/api/v2/configurations/#{@configuration.id}", params: params

      expect(response).to have_http_status(200)
      expect(ApplyConfigurationJob).not_to have_been_enqueued
        .with(json['data']['id'], fake_user.id)
    end

    it 'returns 403 if user is not authorized to update' do
      params = { data: { apply_now: true } }
      login_for_test
      patch "/api/v2/configurations/#{@configuration.id}", params: params

      expect(response).to have_http_status(403)
    end
  end

  describe 'DELETE /api/v2/configurations/:id' do
    it 'delets the configuration state' do
      login_for_test(permissions: correct_permissions)
      delete "/api/v2/configurations/#{@configuration.id}"

      expect(response).to have_http_status(200)
      expect(json['data']['id']).to eq(@configuration.id)
    end

    it 'returns 403 if user is not authorized to delete' do
      login_for_test
      delete "/api/v2/configurations/#{@configuration.id}"

      expect(response).to have_http_status(403)
    end
  end
end
