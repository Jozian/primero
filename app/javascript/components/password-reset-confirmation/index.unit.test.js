import * as index from "./index";

describe("pages/admin - index", () => {
  const indexValues = { ...index };

  it("should have known properties", () => {
    ["default", "NAME"].forEach(property => {
      expect(indexValues).to.have.property(property);
      delete indexValues[property];
    });
    expect(indexValues).to.be.empty;
  });
});
