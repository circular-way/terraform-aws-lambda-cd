/**
 * Lambda handler entrypoint for worker.
 */

const cp = require("child_process")
const fs = require("fs")
const path = require("path")
const { promisify } = require("util")

const aws = require("aws-sdk")
const s3 = new aws.S3()

const exec = promisify(cp.exec)

const eventSource = "io.sellalong.lambda-cd-worker"

/**
 * @typedef {object} WorkerEvent
 * @property {string} time invoke timestamp
 * @property {'BUILD'} detail-type event type
 * @property {typeof eventSource} source event source
 * @property {WorkerBuildEvent} detail event details
 */

/**
 * @typedef {object} WorkerBuildEvent
 * @property {string[]} commands
 * @property {WorkerBuildEventS3} s3
 */

/**
 * @typedef {object} WorkerBuildEventS3
 * @property {{bucket: string, key: string, versionId: string|null}} sources
 * @property {{bucket: string, dir: string, prefix: string}} target
 */

/**
 * @param {unknown} event
 * @returns {event is WorkerEvent}
 */
function isBuildEvent(event) {
  const e = /** @type {WorkerEvent} */ (event)
  return (
    e["detail-type"] === "BUILD" &&
    e.source === eventSource &&
    typeof e.detail === "object" &&
    Array.isArray(e.detail.commands) &&
    typeof e.detail.s3 === "object" &&
    typeof e.detail.s3.sources === "object" &&
    typeof e.detail.s3.sources.bucket === "string" &&
    typeof e.detail.s3.sources.key === "string" &&
    typeof e.detail.s3.target === "object" &&
    typeof e.detail.s3.target.bucket === "string" &&
    typeof e.detail.s3.target.dir === "string" &&
    typeof e.detail.s3.target.prefix === "string"
  )
}

/**
 *
 * @param {string} bucket
 * @param {string} key
 */
async function s3HeadObject(bucket, key) {
  try {
    const response = await s3
      .headObject({
        Bucket: bucket,
        Key: key,
      })
      .promise()
    return {
      bucket,
      key,
      etag: response.ETag,
      version_id: response.VersionId,
      metadata: response.Metadata,
    }
  } catch (error) {
    console.warn(`Existing build not found: ${error}`)
    return null
  }
}

/**
 * @param {string} bucket
 * @param {string} key
 * @param {string|null} versionId
 * @param {string} targetFilePath
 * @returns {Promise<void>}
 */
async function s3Download(bucket, key, versionId, targetFilePath) {
  return new Promise((resolve, reject) => {
    const sourcesTarget = fs.createWriteStream(targetFilePath)
    s3.getObject({
      Bucket: bucket,
      Key: key,
      VersionId: versionId || undefined,
    })
      .createReadStream()
      .on("error", (error) =>
        reject(new Error(`Could not download sources from s3: ${error}`))
      )
      .pipe(sourcesTarget)
      .on("error", (error) =>
        reject(new Error(`Could not download sources from s3: ${error}`))
      )
      .on("finish", () => {
        sourcesTarget.end()
        resolve()
      })
  })
}

/**
 * @param {string} sourceFilePath
 * @param {string} bucket
 * @param {string} key
 * @param {Record<string, string>} metadata
 */
async function s3Upload(sourceFilePath, bucket, key, metadata) {
  const source = fs.createReadStream(sourceFilePath)
  const response = await s3
    .putObject({
      Bucket: bucket,
      Key: key,
      Body: source,
      Metadata: metadata,
    })
    .promise()

  return {
    bucket,
    etag: response.ETag,
    key,
    version_id: response.VersionId,
  }
}

/**
 * @param {string} stdout
 */
function parseBuildScriptOutput(stdout) {
  try {
    const parsed = JSON.parse(stdout)
    const packagePath = parsed.packagePath

    if (typeof packagePath !== "string") {
      throw new Error(`Unexpected json: ${stdout}`)
    }
    return packagePath
  } catch (err) {
    throw new Error(`Could not parse build script output: ${err}`)
  }
}

const encode = encodeURIComponent
const awsEncode = (/** @type {string} */ input) =>
  encode(input).replace(/%/g, "$")

/**
 * @param {number} startTime
 */
function getLogs(startTime) {
  const region =
    process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || "us-east-1"
  const group = process.env.AWS_LAMBDA_LOG_GROUP_NAME || ""
  const stream = process.env.AWS_LAMBDA_LOG_STREAM_NAME || ""

  const console_url =
    `https://${region}.console.aws.amazon.com/cloudwatch/home?region=${region}#logsV2:log-groups/log-group/` +
    awsEncode(encode(group)) +
    "/log-events/" +
    awsEncode(encode(stream)) +
    awsEncode(`?start=${encode(new Date(startTime).toISOString())}`)

  return {
    group: group || "unknown",
    stream: stream || "unknown",
    console_url,
  }
}

/**
 * @template P
 * @param {() => Promise<P>} fn
 * @return {Promise<{elapsed: string, result: P}>}
 */
async function action(fn) {
  console.log(`Starting ${fn.name}`)
  const start = Date.now()
  const result = await fn()
  const elapsed = `${Date.now() - start}ms`

  console.log(`${fn.name} completed in ${elapsed}`)

  return {
    elapsed,
    result,
  }
}

/**
 * @typedef {object} WorkerHandlerOutput
 * @property {{bucket: string, key: string, etag?: string, version_id?: string}} package_s3 target build artefact details in s3
 * @property {string} build_time
 * @property {{group?: string, stream?: string, console_url: string}} logs
 */

/**
 *
 * @param {WorkerEvent} event
 * @returns {Promise<WorkerHandlerOutput>}
 */
module.exports.handler = async function handler(event) {
  const start = Date.now()
  if (!isBuildEvent(event)) {
    throw new Error(`Unexpected event: ${JSON.stringify(event)}`)
  }

  const { sources, target } = event.detail.s3
  const filename = path.basename(sources.key, ".sources.zip")

  const targetS3 = {
    bucket: target.bucket,
    key: `${target.prefix}${filename}.zip`,
  }

  const localBuildPath = `/tmp/build.${start}/`
  const localSourcesPath = `/tmp/${filename}.sources.${start}.zip`
  const localTargetPath = `/tmp/${filename}.target.${start}.zip`

  const { result: existing } = await action(function getExisting() {
    return s3HeadObject(targetS3.bucket, targetS3.key)
  })

  if (existing !== null) {
    const { metadata, ...package_s3 } = existing
    console.log(
      `Build exists, skipping rebuild: s3://${targetS3.bucket}/${targetS3.key}`
    )
    return {
      build_time: metadata?.build_time || "unknown",
      logs: {
        group: metadata?.log_group || "unknown",
        stream: metadata?.log_stream || "unknown",
        console_url: metadata?.log_console_url || "unknown",
      },
      package_s3,
    }
  }

  await action(function downloadSources() {
    return s3Download(
      sources.bucket,
      sources.key,
      sources.versionId,
      localSourcesPath
    )
  })

  const { result: packagePath, elapsed: build_time } = await action(
    async function build() {
      const proc = exec("./build.sh", {
        env: {
          BUILD_COMMAND: event.detail.commands.join(";\n"),
          BUILD_PATH: localBuildPath,
          BUILD_SOURCE_PATH: localSourcesPath,
          BUILD_TARGET_PATH: localTargetPath,
          BUILD_TARGET_DIR: target.dir,

          ...process.env,

          HOME: "/tmp",
        },
      })

      proc.child.stdout?.pipe(process.stdout)
      proc.child.stderr?.pipe(process.stderr)

      const { stdout } = await proc
      return parseBuildScriptOutput(stdout)
    }
  )

  const logs = getLogs(start)

  const { result: package_s3 } = await action(function uploadPackage() {
    return s3Upload(packagePath, targetS3.bucket, targetS3.key, {
      build_time,
      log_group: logs.group,
      log_stream: logs.stream,
      log_console_url: logs.console_url,
    })
  })

  return {
    build_time,
    logs,
    package_s3,
  }
}
