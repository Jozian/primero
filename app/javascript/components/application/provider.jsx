import React, { useContext, createContext, useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import PropTypes from "prop-types";

import { useI18n } from "../i18n";
import { useConnectivityStatus } from "../connectivity";

import { fetchSandboxUI } from "./action-creators";
import { selectModules, selectUserModules, getApprovalsLabels, getDisabledApplication, getDemo } from "./selectors";

const Context = createContext();

const ApplicationProvider = ({ children }) => {
  const dispatch = useDispatch();
  const i18n = useI18n();
  const { online } = useConnectivityStatus();

  const modules = useSelector(state => selectModules(state));
  const userModules = useSelector(state => selectUserModules(state));
  const approvalsLabels = useSelector(state => getApprovalsLabels(state, i18n.locale));
  const disabledApplication = useSelector(state => getDisabledApplication(state));
  const demo = useSelector(state => getDemo(state));

  useEffect(() => {
    dispatch(fetchSandboxUI());
  }, []);

  return (
    <Context.Provider value={{ modules, userModules, online, approvalsLabels, disabledApplication, demo }}>
      {children}
    </Context.Provider>
  );
};

ApplicationProvider.displayName = "ApplicationProvider";

ApplicationProvider.propTypes = {
  children: PropTypes.node.isRequired
};

const useApp = () => useContext(Context);

export { ApplicationProvider, useApp };
