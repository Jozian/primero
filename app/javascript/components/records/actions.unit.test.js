import * as actions from "./actions";

describe("records - Actions", () => {
  it("should have known actions", () => {
    const cloneActions = { ...actions };

    [
      "CASES_RECORDS",
      "CLEAR_METADATA",
      "CLEAR_RECORD_ATTACHMENTS",
      "DELETE_ATTACHMENT_SUCCESS",
      "FETCH_INCIDENT_FROM_CASE",
      "FETCH_INCIDENT_FROM_CASE_FAILURE",
      "FETCH_INCIDENT_FROM_CASE_FINISHED",
      "FETCH_INCIDENT_FROM_CASE_SUCCESS",
      "FETCH_RECORD_ALERTS",
      "FETCH_RECORD_ALERTS_FAILURE",
      "FETCH_RECORD_ALERTS_FINISHED",
      "FETCH_RECORD_ALERTS_STARTED",
      "FETCH_RECORD_ALERTS_SUCCESS",
      "INCIDENTS_RECORDS",
      "RECORD",
      "RECORDS",
      "RECORDS_FAILURE",
      "RECORDS_FINISHED",
      "RECORDS_STARTED",
      "RECORDS_SUCCESS",
      "RECORD_FAILURE",
      "RECORD_FINISHED",
      "RECORD_STARTED",
      "RECORD_SUCCESS",
      "SAVE_ATTACHMENT_SUCCESS",
      "SAVE_RECORD",
      "SAVE_RECORD_FAILURE",
      "SAVE_RECORD_FINISHED",
      "SAVE_RECORD_STARTED",
      "SAVE_RECORD_SUCCESS",
      "SERVICE_REFERRED_SAVE",
      "SET_ATTACHMENT_STATUS",
      "SET_CASE_ID_FOR_INCIDENT",
      "SET_CASE_ID_REDIRECT",
      "SET_SELECTED_RECORD",
      "CLEAR_SELECTED_RECORD",
      "CLEAR_CASE_FROM_INCIDENT",
      "TRACING_REQUESTS_RECORDS",
      "UPDATE_ATTACHMENTS"
    ].forEach(property => {
      expect(cloneActions).to.have.property(property);
      expect(cloneActions[property]).to.be.a("string");
      delete cloneActions[property];
    });

    expect(cloneActions).to.be.empty;
  });
});
