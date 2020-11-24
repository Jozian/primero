import * as index from "./index";

describe("<RecordForm /> - index", () => {
  const indexValues = { ...index };

  it("should have known properties", () => {
    expect(indexValues).to.be.an("object");
    [
      "constructInitialValues",
      "default",
      "FieldRecord",
      "fetchAgencies",
      "fetchForms",
      "fetchLookups",
      "fetchOptions",
      "FormSectionField",
      "getAssignableForms",
      "getAttachmentForms",
      "getAllForms",
      "getErrors",
      "getFields",
      "getFirstTab",
      "getFormNav",
      "getLoadingState",
      "getLocations",
      "getLookups",
      "getOption",
      "getOptionsAreLoading",
      "getRecordForms",
      "getRecordFormsByUniqueId",
      "getReportingLocations",
      "getSelectedForm",
      "getServiceToRefer",
      "getSubformsDisplayName",
      "getValidationErrors",
      "reducer",
      "setSelectedForm"
    ].forEach(property => {
      expect(indexValues).to.have.property(property);
      delete indexValues[property];
    });
    expect(indexValues).to.be.empty;
  });
});
