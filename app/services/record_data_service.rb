# frozen_string_literal: true

# Pulls together the record data for presentation in the JSON API
class RecordDataService
  class << self
    def data(record, user, selected_field_names)
      data = record.data
      data = select_fields(data, selected_field_names)
      data = embed_case_data(data, record, selected_field_names)
      data = embed_user_scope(data, record, selected_field_names, user)
      data = embed_hidden_name(data, record, selected_field_names)
      data = embed_flag_metadata(data, record, selected_field_names)
      data = embed_alert_metadata(data, record, selected_field_names)
      data = embed_photo_metadata(data, record, selected_field_names)
      data = embed_attachments(data, record, selected_field_names)
      embed_associations_as_data(data, record, selected_field_names, user)
    end

    def select_fields(data, selected_field_names)
      data.compact_deep
          .select { |k, _| selected_field_names.include?(k) }
    end

    def embed_user_scope(data, record, selected_field_names, user)
      return data unless selected_field_names.include?('record_in_scope')

      data['record_in_scope'] = user.can?(:read, record)
      data
    end

    def embed_hidden_name(data, record, selected_field_names)
      return data unless selected_field_names.include?('name')

      data['name'] = visible_name(record)
      data
    end

    def embed_flag_metadata(data, record, selected_field_names)
      return data unless selected_field_names.include?('flag_count')

      data['flag_count'] = record.flag_count
      data
    end

    def embed_photo_metadata(data, record, selected_field_names)
      return data unless selected_field_names.include?('photos')

      data['photo'] = record.photo_url
      data
    end

    def embed_attachments(data, record, selected_field_names)
      attachment_field_names = Field.binary.pluck(:name)
      attachment_field_names &= selected_field_names
      return data unless attachment_field_names.present?

      attachments = record.attachments
      attachment_field_names.each do |field_name|
        for_field = attachments.select { |a| a.field_name == field_name }
        data[field_name] = for_field.map(&:to_h_api)
      end
      data
    end

    def embed_alert_metadata(data, record, selected_field_names)
      return data unless selected_field_names.include?('alert_count')

      data['alert_count'] = record.alert_count
      data
    end

    def embed_associations_as_data(data, record, selected_field_names, current_user)
      return data unless (record.associations_as_data_keys & selected_field_names).present?

      data.merge(record.associations_as_data(current_user))
    end

    def visible_name(record)
      record.try(:hidden_name) ? '*******' : record.try(:name)
    end

    def embed_case_data(data, record, selected_field_names)
      return data unless record.class == Incident && record.incident_case_id.present?

      data['incident_case_id'] = record.incident_case_id if selected_field_names.include?('incident_case_id')
      data['case_id_display'] = record.case_id_display if selected_field_names.include?('case_id_display')
      data
    end
  end
end
