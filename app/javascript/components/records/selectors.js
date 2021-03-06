import { Map, List, fromJS } from "immutable";

export const selectRecord = (state, mode, recordType, id) => {
  if (mode.isEdit || mode.isShow) {
    const index = state.getIn(["records", recordType, "data"]).findIndex(r => r.get("id") === id);

    return state.getIn(["records", recordType, "data", index], Map({}));
  }

  return null;
};

export const selectRecordAttribute = (state, recordType, id, attribute) => {
  const index = state.getIn(["records", recordType, "data"], List([])).findIndex(r => r.get("id") === id);

  if (index >= 0) {
    return state.getIn(["records", recordType, "data", index, attribute], "");
  }

  return "";
};

export const selectRecordsByIndexes = (state, recordType, indexes) =>
  (indexes || []).map(index => state.getIn(["records", recordType, "data"], List([])).get(index));

export const getSavingRecord = (state, recordType) => state.getIn(["records", recordType, "saving"], false);

export const getLoadingRecordState = (state, recordType) => state.getIn(["records", recordType, "loading"], false);

export const getRecordAlerts = (state, recordType) => state.getIn(["records", recordType, "recordAlerts"], List([]));

export const getRecordFormAlerts = (state, recordType, formUniqueId) =>
  state
    .getIn(["records", recordType, "recordAlerts"], List([]))
    .filter(alert => alert.get("form_unique_id") === formUniqueId);

export const getIncidentFromCase = state => {
  return state.getIn(["records", "cases", "incidentFromCase", "data"], fromJS({}));
};

export const getCaseIdForIncident = state => {
  return state.getIn(["records", "cases", "incidentFromCase", "incident_case_id"], false);
};

export const getSelectedRecord = (state, recordType) => state.getIn(["records", recordType, "selectedRecord"]);

export const getRecordAttachments = (state, recordType) =>
  state.getIn(["records", recordType, "recordAttachments"], fromJS({}));

export const getIsProcessingSomeAttachment = (state, recordType) =>
  getRecordAttachments(state, recordType)
    .valueSeq()
    .some(attachment => attachment.get("processing") === true);

export const getIsProcessingAttachments = (state, recordType, fieldName) =>
  getRecordAttachments(state, recordType).getIn([fieldName, "processing"], false);

export const getIsPendingAttachments = (state, recordType, fieldName) =>
  getRecordAttachments(state, recordType).getIn([fieldName, "pending"], false);
