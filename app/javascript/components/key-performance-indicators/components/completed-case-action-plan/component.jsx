import React from "react";
import PropTypes from "prop-types";

import { useI18n } from "../../../i18n";
import StackedPercentageBar from "../stacked-percentage-bar";
import asKeyPerformanceIndicator from "../as-key-performance-indicator";

const Component = ({ data, identifier }) => {
  const i18n = useI18n();

  return (
    <StackedPercentageBar
      percentages={[
        {
          percentage: data.get("data").get("completed"),
          label: i18n.t(`key_performance_indicators.${identifier}.label`)
        }
      ]}
    />
  );
};

Component.displayName = "CompletedCaseActionPlan";

Component.propTypes = {
  data: PropTypes.object,
  identifier: PropTypes.string
};

export default asKeyPerformanceIndicator("completed_case_action_plans", {
  data: { completed: 0 }
})(Component);
