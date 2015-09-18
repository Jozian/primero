require 'spec_helper'

describe ChildrenController do

  shared_examples_for "Remote" do |transition_type|
    it "should export JSON for #{transition_type}" do
      controller.stub :render
      controller.should_receive(:log_to_history).with(records).and_call_original
      controller.should_receive(:remote_transition).with(records).and_call_original
      controller.should_receive(:set_status_transferred).with(records).and_call_original if transition_type == "transfer"
      controller.should_receive(:transition_exporter_properties).with(transition_user).and_call_original
      controller.should_receive(:filter_permitted_export_properties).with(records, transition_properties, transition_user).and_call_original
      Exporters::JSONExporter.should_receive(:export).with(records, permited_properties, @user).and_return("data")
      controller.should_receive(:filename).with(records, Exporters::JSONExporter, transition_type).and_return("test_filename");
      controller.should_receive(:encrypt_data_to_zip).with("data", "test_filename", "password")
      controller.should_receive(:message_success).with(records.size)

      params = {
        "transition_type"=>transition_type,
        "consent_override"=>"true",
        "is_remote"=>"true",
        "transition_role"=>transition_role,
        "other_user"=>"primero_cp",
        "other_user_agency"=>"UNICEF",
        "service"=>"Other Service",
        "notes"=>"Testing",
        "type_of_export"=>"Primero", #This value define that is a JSON file.
        "password"=>"password",
        "file_name"=>""
      }
      if id.present?
        params.merge!({"id"=>id})
      elsif selected_records.present?
        params.merge!({"selected_records"=>selected_records})
      end

      post :transition, params
    end

    it "should export CSV for #{transition_type}" do
      controller.stub :render
      controller.should_receive(:log_to_history).with(records).and_call_original
      controller.should_receive(:remote_transition).with(records).and_call_original
      controller.should_receive(:set_status_transferred).with(records).and_call_original if transition_type == "transfer"
      controller.should_receive(:transition_exporter_properties).with(transition_user).and_call_original
      controller.should_receive(:filter_permitted_export_properties).with(records, transition_properties, transition_user).and_call_original
      Exporters::CSVExporter.should_receive(:export).with(records, permited_properties, @user).and_return("data")
      controller.should_receive(:filename).with(records, Exporters::CSVExporter, transition_type).and_return("test_filename");
      controller.should_receive(:encrypt_data_to_zip).with("data", "test_filename", "password")
      controller.should_receive(:message_success).with(records.size)

      params = {
        "transition_type"=>transition_type,
        "consent_override"=>"true",
        "is_remote"=>"true",
        "transition_role"=>transition_role,
        "other_user"=>"primero_cp",
        "other_user_agency"=>"UNICEF",
        "service"=>"Other Service",
        "notes"=>"Testing",
        "type_of_export"=>"Non-Primero", #This value define that is a CSV file.
        "password"=>"password",
        "file_name"=>""
      }
      if id.present?
        params.merge!({"id"=>id})
      elsif selected_records.present?
        params.merge!({"selected_records"=>selected_records})
      end
      post :transition, params
    end

    it "should export PDF for #{transition_type}", :if => transition_type=="referral" do

      controller.stub :render
      controller.should_receive(:log_to_history).with(records).and_call_original
      controller.should_receive(:remote_transition).with(records).and_call_original
      controller.should_receive(:set_status_transferred).with(records).and_call_original if transition_type == "transfer"
      controller.should_receive(:transition_exporter_properties).with(transition_user).and_call_original
      controller.should_receive(:filter_permitted_export_properties).with(records, pdf_transition_properties, transition_user).and_call_original
      Exporters::PDFExporter.should_receive(:export).with(records, pdf_permited_properties, @user).and_return("data")
      controller.should_receive(:filename).with(records, Exporters::PDFExporter, transition_type).and_return("test_filename");
      controller.should_receive(:encrypt_data_to_zip).with("data", "test_filename", "password")
      controller.should_receive(:message_success).with(records.size)

      params = {
        "transition_type"=>transition_type,
        "consent_override"=>"true",
        "is_remote"=>"true",
        "transition_role"=>transition_role,
        "other_user"=>"primero_cp",
        "other_user_agency"=>"UNICEF",
        "service"=>"Other Service",
        "notes"=>"Testing",
        "type_of_export"=>"PDF export", #This value define that is a PDF file.
        "password"=>"password",
        "file_name"=>""
      }
      if id.present?
        params.merge!({"id"=>id})
      elsif selected_records.present?
        params.merge!({"selected_records"=>selected_records})
      end

      post :transition, params
    end

  end

  describe "Transition" do

    before :each do
      Child.all.each &:destroy
      Role.all.each &:destroy
      FormSection.all.each &:destroy
      PrimeroModule.all.each &:destroy
      fields = [
        Field.new({"name" => "field_name_1",
                   "type" => "text_field",
                   "display_name_all" => "Field Name 1"
                  })
      ]
      form = FormSection.new(
        :unique_id => "form_section_test_1",
        :parent_form=>"case",
        "visible" => true,
        :order_form_group => 50,
        :order => 15,
        :order_subform => 0,
        :form_group_name => "Form Section Test",
        "editable" => true,
        "name_all" => "Form Section Test 1",
        "description_all" => "Form Section Test 1",
        :fields => fields
      )
      form.save!
  
      fields = [
        Field.new({"name" => "field_name_2",
                   "type" => "text_field",
                   "display_name_all" => "Field Name 2"
                  })
      ]
      form = FormSection.new(
        :unique_id => "form_section_test_2",
        :parent_form=>"case",
        "visible" => true,
        :order_form_group => 51,
        :order => 16,
        :order_subform => 0,
        :form_group_name => "Form Section Test",
        "editable" => true,
        "name_all" => "Form Section Test 2",
        "description_all" => "Form Section Test 2",
        :fields => fields
      )
      form.save!
  
      Child.refresh_form_properties
  
      primero_module = PrimeroModule.create!(
          program_id: "primeroprogram-primero",
          name: "CP",
          description: "Child Protection",
          associated_form_ids: ["form_section_test_1", "form_section_test_2"],
          associated_record_types: ['case']
      )
  
      @child = Child.new(
        :unique_identifier => UUIDTools::UUID.random_create.to_s, 
        :last_updated_by => "fakeadmin",
        :module_id => primero_module.id
      )
      @child.save!
  
      @child2 = Child.new(
        :unique_identifier => UUIDTools::UUID.random_create.to_s,
        :last_updated_by => "fakeadmin",
        :module_id => primero_module.id
      )
      @child2.save!
  
      @referal_rol = Role.new(
        :name => "Rol for referal", 
        :permissions => ["export_pdf", "export_json", "export_csv"],
        :permitted_form_ids => ["form_section_test_1"],
        :referral => true
      )
      @referal_rol.save!
  
      @transfer_rol = Role.new(
        :name => "Rol for transfer", 
        :permissions => ["export_pdf", "export_json", "export_csv"],
        :permitted_form_ids => ["form_section_test_2"],
        :transfer => true
      )
      @transfer_rol.save!
  
      @user = User.new(
        :user_name => 'fakeadmin', 
        module_ids: [primero_module.id],
        role_ids: ["role-superuser"]
      )
      @session = fake_admin_login @user
    end

    after :each do
      Role.all.each &:destroy
      Child.all.each &:destroy
      FormSection.all.each &:destroy
      PrimeroModule.all.each &:destroy
      Child.remove_form_properties
    end

    describe "one case" do

      it_behaves_like "Remote", "referral" do
        let(:transition_user) {User.new(role_ids: [@referal_rol.id], module_ids: ["primeromodule-cp", "primeromodule-gbv"])}
        let(:pdf_permited_properties) {{"primeromodule-cp"=>{"Form Section Test 1"=>{"field_name_1"=> Child.properties.select{|p| p.name == "field_name_1"}.first}}}}
        let(:pdf_transition_properties) {{"primeromodule-cp"=>{"Form Section Test 1"=>{"field_name_1"=> Child.properties.select{|p| p.name == "field_name_1"}.first}}}}
        let(:permited_properties) {Child.properties.select{|p| p.name == "field_name_1" or p.name == "unique_identifier" or p.name == "record_state"}}
        let(:transition_properties) {Child.properties}
        let(:records) {[@child]}
        let(:id) {@child.id}
        let(:selected_records) {nil}
        let(:transition_role) {@referal_rol.id}
      end

      it_behaves_like "Remote", "transfer" do
        let(:transition_user) {User.new(role_ids: [@transfer_rol.id], module_ids: ["primeromodule-cp", "primeromodule-gbv"])}
        let(:permited_properties) {Child.properties.select{|p| p.name == "field_name_2" or p.name == "unique_identifier" or p.name == "record_state"}}
        let(:transition_properties) {Child.properties}
        let(:records) {[@child2]}
        let(:id) {@child2.id}
        let(:selected_records) {nil}
        let(:transition_role) {@transfer_rol.id}
      end

    end

    describe "several cases" do

      it_behaves_like "Remote", "referral" do
        let(:transition_user) {User.new(role_ids: [@referal_rol.id], module_ids: ["primeromodule-cp", "primeromodule-gbv"])}
        let(:pdf_permited_properties) {{"primeromodule-cp"=>{"Form Section Test 1"=>{"field_name_1"=> Child.properties.select{|p| p.name == "field_name_1"}.first}}}}
        let(:pdf_transition_properties) {{"primeromodule-cp"=>{"Form Section Test 1"=>{"field_name_1"=> Child.properties.select{|p| p.name == "field_name_1"}.first}}}}
        let(:permited_properties) {Child.properties.select{|p| p.name == "field_name_1" or p.name == "unique_identifier" or p.name == "record_state"}}
        let(:transition_properties) {Child.properties}
        let(:records) {[@child, @child2]}
        let(:id) {nil}
        let(:selected_records) {"#{@child.id},#{@child2.id}"}
        let(:transition_role) {@referal_rol.id}
      end

      it_behaves_like "Remote", "transfer" do
        let(:transition_user) {User.new(role_ids: [@transfer_rol.id], module_ids: ["primeromodule-cp", "primeromodule-gbv"])}
        let(:permited_properties) {Child.properties.select{|p| p.name == "field_name_2" or p.name == "unique_identifier" or p.name == "record_state"}}
        let(:transition_properties) {Child.properties}
        let(:records) {[@child, @child2]}
        let(:id) {nil}
        let(:selected_records) {"#{@child.id},#{@child2.id}"}
        let(:transition_role) {@transfer_rol.id}
      end

    end

  end

end
