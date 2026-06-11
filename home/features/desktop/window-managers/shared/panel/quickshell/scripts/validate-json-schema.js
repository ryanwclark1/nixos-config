#!/usr/bin/env node

import fs from "fs";

function usage() {
  console.error("Usage: validate-json-schema.js <schema.json> <data.json>");
  process.exit(2);
}

if (process.argv.length < 4) {
  usage();
}

const schemaPath = process.argv[2];
const dataPath = process.argv[3];

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, "utf8"));
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function sameValue(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function validate(schema, value, path, errors) {
  if (schema.const !== undefined && !sameValue(value, schema.const)) {
    errors.push(`${path}: expected const ${JSON.stringify(schema.const)}`);
    return;
  }

  if (Array.isArray(schema.enum) && !schema.enum.some((entry) => sameValue(entry, value))) {
    errors.push(`${path}: expected one of ${JSON.stringify(schema.enum)}`);
    return;
  }

  if (schema.type === "object") {
    if (!isPlainObject(value)) {
      errors.push(`${path}: expected object`);
      return;
    }

    const properties = isPlainObject(schema.properties) ? schema.properties : {};
    const required = Array.isArray(schema.required) ? schema.required : [];
    for (const key of required) {
      if (value[key] === undefined) {
        errors.push(`${path}: missing required property '${key}'`);
      }
    }

    for (const key of Object.keys(properties)) {
      if (value[key] !== undefined) {
        validate(properties[key], value[key], `${path}.${key}`, errors);
      }
    }

    if (schema.additionalProperties === false) {
      for (const key of Object.keys(value)) {
        if (properties[key] === undefined) {
          errors.push(`${path}: unexpected property '${key}'`);
        }
      }
    } else if (isPlainObject(schema.additionalProperties)) {
      for (const key of Object.keys(value)) {
        if (properties[key] === undefined) {
          validate(schema.additionalProperties, value[key], `${path}.${key}`, errors);
        }
      }
    }

    return;
  }

  if (schema.type === "array") {
    if (!Array.isArray(value)) {
      errors.push(`${path}: expected array`);
      return;
    }

    if (schema.items) {
      for (let i = 0; i < value.length; i += 1) {
        validate(schema.items, value[i], `${path}[${i}]`, errors);
      }
    }

    return;
  }

  if (schema.type === "string") {
    if (typeof value !== "string") {
      errors.push(`${path}: expected string`);
    }
    return;
  }

  if (schema.type === "number") {
    if (typeof value !== "number" || Number.isNaN(value)) {
      errors.push(`${path}: expected number`);
    }
    return;
  }

  if (schema.type === "boolean") {
    if (typeof value !== "boolean") {
      errors.push(`${path}: expected boolean`);
    }
  }
}

const schema = readJson(schemaPath);
const data = readJson(dataPath);
const errors = [];

validate(schema, data, "$", errors);

if (errors.length > 0) {
  for (const error of errors) {
    console.error(error);
  }
  process.exit(1);
}
