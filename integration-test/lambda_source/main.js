module.exports.handler = async function handler(event) {
  return {
    "terraform-module-lambda-ci-invoked": true,
    lastExecuted: new Date().toISOString(),
    ...event,
  }
}
