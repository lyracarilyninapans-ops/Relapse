const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const mapsServerApiKey = defineSecret("MAPS_SERVER_API_KEY");
const region = "asia-southeast1";

exports.health = onRequest({region, invoker: "public"}, (req, res) => {
  res.status(200).json({ok: true, service: "relapse-functions"});
});

exports.mapsSecretCheck = onRequest({region, invoker: "public", secrets: [mapsServerApiKey]}, (req, res) => {
  const key = mapsServerApiKey.value();
  logger.info("maps secret check", {hasKey: Boolean(key)});
  res.status(200).json({hasMapsServerApiKey: Boolean(key)});
});
