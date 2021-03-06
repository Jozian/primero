import isObject from "lodash/isObject";

import { DB_COLLECTIONS_NAMES } from "../../db";
import { RECORD_PATH } from "../../config/constants";
import { ENQUEUE_SNACKBAR } from "../notifier";
import { CLEAR_DIALOG } from "../action-dialog";
import RecordFormActions from "../record-form/actions";

import * as actionCreators from "./action-creators";
import { CLEAR_CASE_FROM_INCIDENT, FETCH_RECORD_ALERTS } from "./actions";

describe("records - Action Creators", () => {
  it("should have known action creators", () => {
    const creators = { ...actionCreators };

    [
      "DEPRECATED setFilters",
      "DEPRECATED fetchCases",
      "DEPRECATED fetchIncidents",
      "DEPRECATED fetchTracingRequests"
    ].forEach(property => {
      expect(creators).to.not.have.property(property);
      delete creators[property];
    });

    [
      "clearCaseFromIncident",
      "clearMetadata",
      "clearRecordAttachments",
      "clearSelectedRecord",
      "fetchIncidentFromCase",
      "fetchIncidentwitCaseId",
      "fetchRecord",
      "fetchRecordsAlerts",
      "saveRecord",
      "setCaseIdForIncident",
      "setSelectedRecord",
      "updateRecordAttachments"
    ].forEach(property => {
      expect(creators).to.have.property(property);
      expect(creators[property]).to.be.a("function");
      delete creators[property];
    });

    expect(creators).to.be.empty;
  });

  it("should check the 'fetchRecord' action creator to return the correct object", () => {
    const expected = {
      type: `${RECORD_PATH.cases}/RECORD`,
      api: {
        path: `${RECORD_PATH.cases}/123`,
        db: {
          collection: DB_COLLECTIONS_NAMES.RECORDS,
          recordType: RECORD_PATH.cases,
          id: "123"
        }
      }
    };

    expect(actionCreators.fetchRecord("cases", "123")).to.deep.equal(expected);
  });

  describe("should check the 'saveRecord' action creator", () => {
    const body = {
      data: {
        name_first: "Gerald",
        name_last: "Padgett",
        name_given_post_separation: "true",
        registration_date: "2019-08-06",
        sex: "male",
        age: 26,
        date_of_birth: "1993-06-05",
        module_id: "primeromodule-cp"
      }
    };

    it("when path it's 'update' should return the correct object", () => {
      const messageFn = () => {};
      const expected = {
        type: "cases/SAVE_RECORD",
        api: {
          id: "123",
          recordType: RECORD_PATH.cases,
          path: "cases/123",
          method: "PATCH",
          body,
          successCallback: [
            {
              action: "notifications/ENQUEUE_SNACKBAR",
              incidentPath: "",
              moduleID: undefined,
              payload: {
                message: messageFn,
                messageFromQueue: undefined,
                options: {
                  key: "",
                  variant: "success"
                }
              },
              redirect: "/cases",
              redirectWithIdFromResponse: false
            },
            {
              action: "cases/FETCH_RECORD_ALERTS",
              api: {
                path: "cases/123/alerts",
                performFromQueue: true,
                skipDB: true
              }
            }
          ],
          db: {
            collection: DB_COLLECTIONS_NAMES.RECORDS,
            recordType: RECORD_PATH.cases
          },
          queueAttachments: true,
          queueOffline: true
        }
      };

      expect(actionCreators.saveRecord("cases", "update", body, "123", messageFn)).to.deep.equal(expected);
    });

    it("when path it's not 'update', the path and method should be different", () => {
      const messageFn = () => {};
      const expected = {
        type: "cases/SAVE_RECORD",
        api: {
          id: "123",
          recordType: RECORD_PATH.cases,
          path: "cases/123",
          method: "PATCH",
          body,
          successCallback: [
            {
              action: "notifications/ENQUEUE_SNACKBAR",
              incidentPath: "",
              moduleID: undefined,
              payload: {
                message: messageFn,
                messageFromQueue: undefined,
                options: {
                  key: "",
                  variant: "success"
                }
              },
              redirect: "/cases",
              redirectWithIdFromResponse: false
            },
            {
              action: "cases/FETCH_RECORD_ALERTS",
              api: {
                path: "cases/123/alerts",
                performFromQueue: true,
                skipDB: true
              }
            }
          ],
          db: {
            collection: DB_COLLECTIONS_NAMES.RECORDS,
            recordType: RECORD_PATH.cases
          },
          queueAttachments: true,
          queueOffline: true
        }
      };

      expect(actionCreators.saveRecord("cases", "update", body, "123", messageFn)).to.deep.equal(expected);
    });

    it("should return 3 success callback actions if there is a dialogName", () => {
      const expected = [ENQUEUE_SNACKBAR, CLEAR_DIALOG, `${RECORD_PATH.cases}/${FETCH_RECORD_ALERTS}`];

      const successCallbacks = actionCreators
        .saveRecord(RECORD_PATH.cases, "update", body, "123", "Saved Successfully", false, false, false, "testDialog")
        .api.successCallback.map(callback => callback.action);

      expect(successCallbacks).to.be.an("array");
      expect(successCallbacks).to.have.lengthOf(3);
      expect(successCallbacks).to.deep.equal(expected);
    });

    it("should return 4 success callback actions when is an incidentFromCase", () => {
      const expected = [
        ENQUEUE_SNACKBAR,
        `cases/${CLEAR_CASE_FROM_INCIDENT}`,
        RecordFormActions.SET_SELECTED_FORM,
        `${RECORD_PATH.incidents}/${FETCH_RECORD_ALERTS}`
      ];

      const successCallbacks = actionCreators
        .saveRecord(RECORD_PATH.incidents, "update", body, "123", "Saved Successfully", false, false, false, "", true)
        .api.successCallback.map(callback => callback.action);

      expect(successCallbacks).to.be.an("array");
      expect(successCallbacks).to.have.lengthOf(4);
      expect(successCallbacks).to.deep.equal(expected);
    });

    it("should return 5 success callback actions when incidentPath is included", () => {
      const expected = [
        ENQUEUE_SNACKBAR,
        `cases/${CLEAR_CASE_FROM_INCIDENT}`,
        RecordFormActions.SET_SELECTED_FORM,
        "cases/SET_CASE_ID_REDIRECT",
        `${RECORD_PATH.incidents}/${FETCH_RECORD_ALERTS}`
      ];

      const successCallbacks = actionCreators
        .saveRecord(
          RECORD_PATH.incidents,
          "update",
          body,
          "123",
          "Saved Successfully",
          false,
          false,
          false,
          "",
          true,
          "primeromodule-cp",
          "incident/new"
        )
        .api.successCallback.map(callback => (isObject(callback) ? callback.action : callback));

      expect(successCallbacks).to.be.an("array");
      expect(successCallbacks).to.have.lengthOf(5);
      expect(successCallbacks).to.deep.equal(expected);
      expect(successCallbacks[3]).to.eql("cases/SET_CASE_ID_REDIRECT");
    });
  });

  it("should check the 'fetchRecordsAlerts' action creator to return the correct object", () => {
    const recordId = "123abc";
    const expected = {
      api: {
        path: `${RECORD_PATH.cases}/${recordId}/alerts`,
        skipDB: true,
        performFromQueue: true
      },
      type: `${RECORD_PATH.cases}/FETCH_RECORD_ALERTS`
    };

    expect(actionCreators.fetchRecordsAlerts(RECORD_PATH.cases, recordId)).be.deep.equals(expected);
  });

  it("should check the 'clearMetadata' action creator to return the correct object", () => {
    const expected = {
      type: "TestRecordType/CLEAR_METADATA"
    };

    expect(actionCreators.clearMetadata("TestRecordType")).be.deep.equals(expected);
  });

  it("should check the 'clearCaseFromIncident' action creator to return the correct object", () => {
    const expected = {
      type: "cases/CLEAR_CASE_FROM_INCIDENT"
    };

    expect(actionCreators.clearCaseFromIncident()).be.deep.equals(expected);
  });

  it("should check the 'fetchIncidentFromCase' action creator to return the correct object", () => {
    const expected = {
      type: "cases/FETCH_INCIDENT_FROM_CASE",
      api: {
        path: `cases/case-unique-id-1/incidents/new`,
        successCallback: {
          action: `cases/SET_CASE_ID_FOR_INCIDENT`,
          payload: { caseId: "case-unique-id-1", caseIdDisplay: "case-display-id-1" },
          redirect: "/incidents/module-id-1/new"
        }
      }
    };

    expect(actionCreators.fetchIncidentFromCase("case-unique-id-1", "case-display-id-1", "module-id-1")).be.deep.equals(
      expected
    );
  });

  it("should check the 'setCaseIdForIncident' action creator to return the correct object", () => {
    const expected = {
      type: "cases/SET_CASE_ID_FOR_INCIDENT",
      payload: { caseId: "case-unique-id-1", caseIdDisplay: "case-display-id-1" }
    };

    expect(actionCreators.setCaseIdForIncident("case-unique-id-1", "case-display-id-1")).to.deep.equal(expected);
  });

  it("should check the 'fetchIncidentwitCaseId' action creator to return the correct object", () => {
    const expected = {
      type: "cases/FETCH_INCIDENT_FROM_CASE",
      api: {
        path: "cases/case-id-1/incidents/new"
      }
    };

    expect(actionCreators.fetchIncidentwitCaseId("case-id-1")).to.deep.equal(expected);
  });

  it("should check the 'setSelectedRecord' action creator to return the correct object", () => {
    const recordId = "123abc";

    const expected = {
      type: `${RECORD_PATH.cases}/SET_SELECTED_RECORD`,
      payload: { id: recordId }
    };

    expect(actionCreators.setSelectedRecord(RECORD_PATH.cases, recordId)).be.deep.equals(expected);
  });

  it("should check the 'clearSelectedRecord' action creator to return the correct object", () => {
    const expected = { type: `${RECORD_PATH.cases}/CLEAR_SELECTED_RECORD` };

    expect(actionCreators.clearSelectedRecord(RECORD_PATH.cases)).be.deep.equals(expected);
  });

  it("should check the 'updateRecordAttachments' action creator to return the correct object", () => {
    const expected = {
      type: `${RECORD_PATH.cases}/UPDATE_ATTACHMENTS`,
      payload: { id: 10, recordType: RECORD_PATH.cases }
    };

    expect(actionCreators.updateRecordAttachments(10, RECORD_PATH.cases)).be.deep.equals(expected);
  });

  it("should check the 'clearRecordAttachments' action creator to return the correct object", () => {
    const expected = {
      type: `${RECORD_PATH.cases}/CLEAR_RECORD_ATTACHMENTS`,
      payload: { id: 10, recordType: RECORD_PATH.cases }
    };

    expect(actionCreators.clearRecordAttachments(10, RECORD_PATH.cases)).be.deep.equals(expected);
  });
});
