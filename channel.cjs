'use strict';

// Static channel data only. Validation is NOT signature verification or permission
// to install an executable. The existing launcher does not consume this file yet.
const MAX_CHANNEL_BYTES = 64 * 1024;
const MAX_ASSET_BYTES = 2 ** 31 - 1;
const TARGETS = new Set(['win32-x64', 'win32-arm64', 'darwin-x64', 'darwin-arm64']);
const CHANNELS = new Set(['beta', 'stable']);
const ROOT_KEYS = ['schemaVersion', 'product', 'repository', 'channel', 'version', 'publishedAt', 'artifacts'];
const ARTIFACT_KEYS = ['platform', 'arch', 'filename', 'bytes', 'sha256', 'url'];

/** Reject unexpected public fields rather than copying arbitrary build metadata. */
function exactObject(value, keys, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(value))) {
    throw new Error(`${label} must be a plain object.`);
  }
  const own = Reflect.ownKeys(value);
  if (own.length !== keys.length || keys.some(key => !Object.hasOwn(value, key)) ||
      own.some(key => typeof key !== 'string' || !keys.includes(key))) {
    throw new Error(`${label} has missing or unexpected fields.`);
  }
  if (own.some(key => !Object.hasOwn(Object.getOwnPropertyDescriptor(value, key), 'value'))) {
    throw new Error(`${label} must contain data, not getters or setters.`);
  }
}

function repositoryName(value) {
  // Deliberately accept conventional GitHub owner/repo names, not URLs or paths.
  if (typeof value !== 'string' || value.length > 140 || value.trim() !== value ||
      !/^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?\/[A-Za-z0-9][A-Za-z0-9._-]{0,99}$/.test(value)) {
    throw new Error('Configure a GitHub downloads repository as owner/name.');
  }
  return value;
}

function channelName(value) {
  if (!CHANNELS.has(value)) throw new Error('Release channel must be beta or stable.');
  return value;
}

function releaseVersion(value, channel) {
  if (typeof value !== 'string' || value.length > 96 || value.trim() !== value ||
      !/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/.test(value)) {
    throw new Error('Use an exact release version, for example 0.1.0-beta.1.');
  }
  const suffix = value.includes('-') ? value.slice(value.indexOf('-') + 1) : '';
  if (suffix.split('.').some(part => /^\d+$/.test(part) && part.length > 1 && part.startsWith('0'))) {
    throw new Error('Numeric prerelease identifiers must not have leading zeros.');
  }
  if (channel === 'stable' && suffix) throw new Error('A stable channel cannot select a prerelease version.');
  return value;
}

function timestamp(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(value) ||
      !Number.isFinite(Date.parse(value)) || new Date(value).toISOString() !== value) {
    throw new Error('publishedAt must be a valid UTC ISO timestamp with milliseconds.');
  }
  return value;
}

function checkedArtifact(value, repository, version, withUrl) {
  exactObject(value, withUrl ? ARTIFACT_KEYS : ARTIFACT_KEYS.filter(key => key !== 'url'), 'Release artifact');
  const { platform, arch, filename, bytes, sha256 } = value;
  if (typeof platform !== 'string' || typeof arch !== 'string' || !TARGETS.has(`${platform}-${arch}`)) {
    throw new Error('Release artifact must specify a Windows or macOS x64/arm64 target.');
  }
  const stem = `design-editor-${version}-${platform}-${arch}`;
  if (filename !== `${stem}.zip` && !(platform === 'darwin' && filename === `${stem}.tar.gz`)) {
    throw new Error('Artifact filename must match its version, platform, architecture and archive type.');
  }
  if (!Number.isSafeInteger(bytes) || bytes <= 0 || bytes > MAX_ASSET_BYTES) {
    throw new Error('Artifact byte count must be positive and below 2 GiB.');
  }
  if (typeof sha256 !== 'string' || sha256.length !== 64 || !/^[a-f0-9]{64}$/.test(sha256)) {
    throw new Error('Artifact SHA-256 must contain 64 lowercase hexadecimal characters.');
  }
  // Versioned assets, never /latest, an arbitrary URL, or a private source address.
  const url = `https://github.com/${repository}/releases/download/v${version}/${filename}`;
  if (withUrl && value.url !== url) throw new Error('Artifact URL does not match the configured downloads repository and release.');
  return Object.freeze({ platform, arch, filename, bytes, sha256, url });
}

function checkedArtifacts(values, repository, version, withUrl) {
  if (!Array.isArray(values) || values.length < 1 || values.length > TARGETS.size) {
    throw new Error('List one to four actual release artifacts; do not invent missing builds.');
  }
  for (let index = 0; index < values.length; index++) {
    if (!Object.hasOwn(values, index)) throw new Error('Release artifact list must not contain empty slots.');
  }
  const seen = new Set();
  const artifacts = values.map(value => {
    const artifact = checkedArtifact(value, repository, version, withUrl);
    const target = `${artifact.platform}-${artifact.arch}`;
    if (seen.has(target)) throw new Error('Release contains duplicate platform/architecture targets.');
    seen.add(target);
    return artifact;
  });
  artifacts.sort((a, b) => `${a.platform}-${a.arch}` < `${b.platform}-${b.arch}` ? -1 : 1);
  return Object.freeze(artifacts);
}

/** Build a public-safe data record from explicit asset summaries; no I/O or upload. */
function createChannel(input) {
  exactObject(input, ['repository', 'channel', 'version', 'publishedAt', 'artifacts'], 'Release input');
  const repository = repositoryName(input.repository);
  const channel = channelName(input.channel);
  const version = releaseVersion(input.version, channel);
  return Object.freeze({
    schemaVersion: 1,
    product: 'design-editor',
    repository,
    channel,
    version,
    publishedAt: timestamp(input.publishedAt),
    artifacts: checkedArtifacts(input.artifacts, repository, version, false),
  });
}

/** Expected repository/channel must come from our configuration, NOT the payload. */
function validateChannel(value, expected) {
  exactObject(expected, ['repository', 'channel'], 'Expected release source');
  const repository = repositoryName(expected.repository);
  const channel = channelName(expected.channel);
  exactObject(value, ROOT_KEYS, 'Channel document');
  if (value.schemaVersion !== 1 || value.product !== 'design-editor') {
    throw new Error('Unsupported release schema or product.');
  }
  if (value.repository !== repository || value.channel !== channel) {
    throw new Error('Channel does not match the configured release source.');
  }
  const version = releaseVersion(value.version, channel);
  return Object.freeze({
    schemaVersion: 1, product: 'design-editor', repository, channel, version,
    publishedAt: timestamp(value.publishedAt),
    artifacts: checkedArtifacts(value.artifacts, repository, version, true),
  });
}

function parseChannel(text, expected) {
  if (typeof text !== 'string' || Buffer.byteLength(text, 'utf8') > MAX_CHANNEL_BYTES) {
    throw new Error('Channel JSON must be text within the 64 KiB limit.');
  }
  let value;
  try { value = JSON.parse(text); }
  catch { throw new Error('Release metadata is not valid JSON.'); }
  return validateChannel(value, expected);
}

/** A missing target remains missing; never silently fall back to another machine. */
function selectArtifact(document, target, expected) {
  exactObject(target, ['platform', 'arch'], 'Requested target');
  const channel = validateChannel(document, expected);
  return channel.artifacts.find(item => item.platform === target.platform && item.arch === target.arch) || null;
}

module.exports = { createChannel, validateChannel, parseChannel, selectArtifact, releaseVersion, MAX_CHANNEL_BYTES, MAX_ASSET_BYTES };
