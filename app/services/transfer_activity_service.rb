# frozen_string_literal: true

# Query for transfer in record history for a specific user
class TransferActivityService
  class << self
    def list(user)
      return RecordHistory.none unless user.present?

      transfer_query(RecordHistory.includes(:record), user)
    end

    private

    def transfer_query(query, user)
      accepted_transfer_query(query, user).or(
        rejected_transfer_query(query, user)
      ).order('datetime DESC')
    end

    def accepted_transfer_query(query, user)
      query.where(
        'record_changes @> ?',
        { transfer_status: { from: Transition::STATUS_INPROGRESS, to: Transition::STATUS_ACCEPTED } }.to_json
      ).where('record_changes->\'owned_by\'->\'from\' <@ ?', user.managed_user_names.to_json)
    end

    def rejected_transfer_query(query, user)
      query.where(
        'record_changes @> ?',
        { transfer_status: { from: Transition::STATUS_INPROGRESS, to: Transition::STATUS_REJECTED } }.to_json
      ).where('record_changes->\'assigned_user_names\'->\'from\' <@ ?', user.managed_user_names.to_json)
    end
  end
end
