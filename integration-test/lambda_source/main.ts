import { Handler } from "aws-lambda"

export const handler: Handler = async function handler(event) {
  return {
    "terraform-module-lambda-ci-invoked": true,
    ...event,
  }
}
