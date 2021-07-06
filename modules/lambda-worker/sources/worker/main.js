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
 * @property {{bucket: string, prefix: string|null}} target
 */

/**
 * @param {unknown} event
 * @returns {event is WorkerEvent}
 */
function isBuildEvent(event) {
  /** @type {WorkerEvent} */
  const e = event
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
    typeof e.detail.s3.target.bucket === "string"
  )
}

/**
 *
 * @param {string} bucket
 * @param {string} key
 */
async function getExisting(bucket, key) {
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
 */
async function s3Upload(sourceFilePath, bucket, key) {
  const source = fs.createReadStream(sourceFilePath)
  const response = await s3
    .putObject({
      Bucket: bucket,
      Key: key,
      Body: source,
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

/**
 * @typedef {object} WorkerHandlerOutput
 * @property {{bucket: string, key: string, etag?: string, version_id?: string}} package_s3 target build artefact details in s3
 */

/**
 *
 * @param {WorkerEvent} event
 * @returns {Promise<WorkerHandlerOutput>}
 */
module.exports.handler = async function handler(event) {
  if (!isBuildEvent(event)) {
    throw new Error(`Unexpected event: ${JSON.stringify(event)}`)
  }

  const { sources, target } = event.detail.s3
  const filename = path.basename(sources.key, ".sources.zip")

  const targetS3 = {
    bucket: target.bucket,
    key: `${target.prefix}${filename}.zip`,
  }

  const existing = await getExisting(targetS3.bucket, targetS3.key)

  if (existing !== null) {
    console.log(
      `Build exists, skipping rebuild: s3://${targetS3.bucket}/${targetS3.key}`
    )
    return {
      package_s3: existing,
    }
  }

  const seed = Date.now()
  const localBuildPath = `/tmp/build.${seed}/`
  const localSourcesPath = `/tmp/${filename}.sources.${seed}.zip`
  const localTargetPath = `/tmp/${filename}.target.${seed}.zip`

  await s3Download(
    sources.bucket,
    sources.key,
    sources.versionId,
    localSourcesPath
  )

  const proc = exec("./build.sh", {
    env: {
      BUILD_COMMAND: event.detail.commands.join(";\n"),
      BUILD_PATH: localBuildPath,
      BUILD_SOURCE_PATH: localSourcesPath,
      BUILD_TARGET_PATH: localTargetPath,

      ...process.env,

      HOME: "/tmp",
    },
  })

  proc.child.stdout.pipe(process.stdout)
  proc.child.stderr.pipe(process.stderr)

  const { stdout } = await proc
  const packagePath = parseBuildScriptOutput(stdout)

  const package_s3 = await s3Upload(packagePath, targetS3.bucket, targetS3.key)

  return {
    package_s3,
  }
}
