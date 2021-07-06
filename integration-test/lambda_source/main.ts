import { Handler } from "aws-lambda"

export const handler: Handler<{}, any> = async function handler(event) {
  return {
    "terraform-module-lambda-ci-invoked": true,
    triggerBuild: false,
    lastExecuted: new Date().toISOString(),
    ...event,
  }
}
