import { fromJS } from "immutable";

import { setupMountedComponent, listHeaders, lookups } from "../../../../test";
import IndexTable from "../../../index-table";
import { ACTIONS } from "../../../../libs/permissions";
import { Filters as AdminFilters } from "../components";

import NAMESPACE from "./namespace";
import actions from "./actions";
import ImportDialog from "./import-dialog";
import LocationsList from "./container";

describe("<LocationsList />", () => {
  let component;
  const dataLength = 30;
  const data = Array.from({ length: dataLength }, (_, i) => ({
    id: i + 1,
    name: { en: `Location ${i + 1}` }
  }));

  beforeEach(() => {
    const initialState = fromJS({
      records: {
        admin: {
          locations: {
            data,
            metadata: { total: dataLength, per: 20, page: 1 },
            loading: false,
            errors: false
          }
        }
      },
      forms: {
        options: {
          lookups: lookups()
        }
      },
      user: {
        permissions: {
          locations: [ACTIONS.MANAGE]
        },
        listHeaders: {
          locations: listHeaders(NAMESPACE)
        }
      }
    });

    ({ component } = setupMountedComponent(LocationsList, {}, initialState, ["/admin/locations"]));
  });

  it("renders record list table", () => {
    expect(component.find(IndexTable)).to.have.lengthOf(1);
  });

  it("renders <AdminFilters /> component", () => {
    expect(component.find(AdminFilters)).to.have.lengthOf(1);
  });

  it("renders <ImportDialog /> component", () => {
    expect(component.find(ImportDialog)).to.have.lengthOf(1);
  });

  it("should trigger a valid action with next page when clicking next page", () => {
    const indexTable = component.find(IndexTable);
    const expectAction = {
      api: {
        params: { total: dataLength, per: 20, page: 2, disabled: ["false"], hierarchy: true },
        path: NAMESPACE
      },
      type: actions.LOCATIONS
    };

    expect(indexTable.find("p").at(2).text()).to.be.equals(`1-20 of ${dataLength}`);
    expect(component.props().store.getActions()).to.have.lengthOf(2);

    indexTable.find("#pagination-next").at(0).simulate("click");

    expect(indexTable.find("p").at(2).text()).to.be.equals(`21-${dataLength} of ${dataLength}`);
    expect(component.props().store.getActions()[2]).to.deep.equals(expectAction);
  });
});
