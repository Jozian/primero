import React from "react";
import PropTypes from "prop-types";
import { useSelector } from "react-redux";
import { Stepper, Step, StepLabel } from "@material-ui/core";
import { MuiThemeProvider, makeStyles } from "@material-ui/core/styles";

import { getWorkflowIndividualCases } from "../../selectors";
import { useI18n } from "../../../../i18n";
import Permission from "../../../../application/permission";
import { selectModule } from "../../../../application";
import { RESOURCES, ACTIONS } from "../../../../../libs/permissions";
import { OptionsBox } from "../../../../dashboard";
import { MODULES, RECORD_TYPES } from "../../../../../config";

import workflowTheme from "./theme";
import styles from "./styles.css";
import { NAME, CLOSED } from "./constants";
import WorkFlowStep from "./components";

const Component = ({ loadingIndicator }) => {
  const i18n = useI18n();
  const css = makeStyles(styles)();
  const workflowLabels = useSelector(
    state => selectModule(state, MODULES.CP)?.workflows?.[RECORD_TYPES.cases]?.[i18n.locale]
  );
  const casesWorkflow = useSelector(state => getWorkflowIndividualCases(state));

  const renderSteps = workflowLabels
    ?.filter(step => step.id !== CLOSED)
    ?.map(step => {
      return (
        <Step key={step.id} active complete>
          <StepLabel>{step.display_text || ""}</StepLabel>
          <WorkFlowStep step={step} css={css} casesWorkflow={casesWorkflow} i18n={i18n} />
        </Step>
      );
    });

  return (
    <Permission resources={RESOURCES.dashboards} actions={ACTIONS.DASH_WORKFLOW}>
      <OptionsBox title={i18n.t("dashboard.workflow")} hasData={Boolean(casesWorkflow.size)} {...loadingIndicator}>
        <MuiThemeProvider theme={workflowTheme}>
          <Stepper>{renderSteps}</Stepper>
        </MuiThemeProvider>
      </OptionsBox>
    </Permission>
  );
};

Component.displayName = NAME;

Component.propTypes = {
  loadingIndicator: PropTypes.object
};

export default Component;
