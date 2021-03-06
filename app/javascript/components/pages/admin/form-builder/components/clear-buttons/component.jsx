/* eslint-disable react/no-multi-comp, react/display-name */
import React from "react";
import PropTypes from "prop-types";
import CloseIcon from "@material-ui/icons/Close";
import { makeStyles } from "@material-ui/core/styles";

import { useI18n } from "../../../../../i18n";
import { ACTION_BUTTON_TYPES } from "../../../../../action-button/constants";
import ActionButton from "../../../../../action-button";
import { SUBFORM_GROUP_BY, SUBFORM_SECTION_CONFIGURATION, SUBFORM_SORT_BY } from "../field-list-item/constants";

import { NAME, GROUP_BY, SORT_BY } from "./constants";
import styles from "./styles.css";

const Component = ({ setValue, subformField, subformSortBy, subformGroupBy }) => {
  const css = makeStyles(styles)();
  const i18n = useI18n();
  const fieldName = subformField.get("name");

  const onClearSortBy = () => {
    setValue(`${fieldName}.${SUBFORM_SECTION_CONFIGURATION}.${SUBFORM_SORT_BY}`, "");
  };

  const onClearGroupBy = () => {
    setValue(`${fieldName}.${SUBFORM_SECTION_CONFIGURATION}.${SUBFORM_GROUP_BY}`, "");
  };

  const renderClearButton = (fieldBy, onClick) =>
    ((fieldBy === SORT_BY && subformSortBy) || (fieldBy === GROUP_BY && subformGroupBy)) && (
      <ActionButton
        icon={<CloseIcon />}
        text={i18n.t(`fields.clear_${fieldBy}`)}
        type={ACTION_BUTTON_TYPES.default}
        isCancel
        rest={{
          onClick
        }}
      />
    );

  return (
    <div className={css.fieldRow}>
      <div className={css.fieldColumn}>{renderClearButton(SORT_BY, onClearSortBy)}</div>
      <div className={css.fieldColumn}>{renderClearButton(GROUP_BY, onClearGroupBy)}</div>
    </div>
  );
};

Component.displayName = NAME;

Component.propTypes = {
  setValue: PropTypes.func.isRequired,
  subformField: PropTypes.object,
  subformGroupBy: PropTypes.string,
  subformSortBy: PropTypes.string
};

export default Component;
