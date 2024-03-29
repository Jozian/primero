import differenceWith from "lodash/differenceWith";
import intersection from "lodash/intersection";
import isEmpty from "lodash/isEmpty";
import isEqual from "lodash/isEqual";

import { compactValues } from "../../record-form/utils";
import generateKey from "../../charts/table-values/utils";
import { EMPTY_VALUE, TYPE } from "../constants";

import getTranslatedValue from "./get-translated-value";
import getFieldAndValuesTranslations from "./get-field-and-values-translations";

const getShortId = changes => {
  const uniqueId = changes[changes.valueToRender];

  return uniqueId.substr(uniqueId.length - 7);
};

const addedDeletedCompare = (currFrom, currTo) => currFrom.unique_id === currTo.unique_id;

const getDiffFromEditedSubform = (valueFrom, valueTo) => {
  const fromIds = valueFrom?.map(val => val.unique_id) || [];
  const toIds = valueTo?.map(val => val.unique_id) || [];
  const editedSubformsIds = intersection(fromIds, toIds);

  return editedSubformsIds.reduce((acc, subform) => {
    const currFromSubform = valueFrom.find(val => val.unique_id === subform);
    const currToSubform = valueTo.find(val => val.unique_id === subform);

    if (isEqual(currFromSubform, currToSubform)) {
      return acc;
    }

    const uniqueId = { unique_id: { from: currFromSubform.unique_id, to: currFromSubform.unique_id } };
    const differences = Object.entries(compactValues(currFromSubform, currToSubform)).reduce(
      (accum, curr) => ({ ...accum, [curr[0]]: { from: curr[1], to: currToSubform[curr[0]] } }),
      {}
    );

    return [
      ...acc,
      {
        ...uniqueId,
        ...differences
      }
    ];
  }, []);
};

const getSubformChanges = (valueFrom, valueTo) => ({
  updated: getDiffFromEditedSubform(valueFrom, valueTo),
  added: differenceWith(valueTo, valueFrom, addedDeletedCompare),
  deleted: differenceWith(valueFrom, valueTo, addedDeletedCompare)
});

const generateFieldDetails = (type, subformName, log, allFields, allLookups, locations, i18n) =>
  Object.entries(log).reduce(
    (acc, curr) => {
      const [fieldName, fieldChanges] = curr;

      const currentChanges = {
        [TYPE.added]: { from: EMPTY_VALUE, to: fieldChanges, valueToRender: "to", title: "change_logs.add_subform" },
        [TYPE.deleted]: {
          from: fieldChanges,
          to: EMPTY_VALUE,
          valueToRender: "from",
          title: "change_logs.deleted_subform"
        },
        [TYPE.updated]: { ...fieldChanges, valueToRender: "to", title: "change_logs.updated_subform" }
      }[type];

      if (fieldName === "unique_id") {
        acc.title = i18n.t(currentChanges.title, {
          subform_name: subformName,
          short_id: getShortId(currentChanges)
        });

        return acc;
      }

      const fieldRecord = allFields.filter(recordField => recordField.name === fieldName)?.first();
      const dateIncludeTime = fieldRecord?.get("date_include_time");

      const fieldsTranslated = getFieldAndValuesTranslations(
        allLookups,
        locations,
        i18n,
        fieldRecord,
        fieldName,
        currentChanges
      );

      if (type !== TYPE.deleted) {
        acc.details = [
          ...acc.details,
          {
            name: fieldsTranslated.fieldDisplayName || fieldName,
            from: getTranslatedValue(fieldsTranslated.fieldValueFrom, dateIncludeTime, i18n),
            to: getTranslatedValue(fieldsTranslated.fieldValueTo, dateIncludeTime, i18n)
          }
        ];
      }

      return acc;
    },
    { title: "", details: [] }
  );

export default (recordChanges, allFields, allLookups, locations, i18n) => {
  const result = Object.entries(getSubformChanges(recordChanges.value.from, recordChanges.value.to)).reduce(
    (acc, subformLog) => {
      const [type, logs] = subformLog;

      if (isEmpty(logs)) {
        return acc;
      }

      const logItem = logs.reduce((accum, changes) => {
        return [
          ...accum,
          {
            key: `subfom-log-${generateKey()}`,
            ...recordChanges.commonProps,
            ...generateFieldDetails(type, recordChanges?.subformName, changes, allFields, allLookups, locations, i18n)
          }
        ];
      }, []);

      return [...acc, ...logItem];
    },
    []
  );

  return result;
};
