'use strict';
// Canonical publication tooling. export-release-automation.cjs copies this and
// the existing schema-1 channel validator into the two public repositories.
// Packages are data here: no private checkout, extraction, or project execution.
const fs = require('node:fs');
const fsp = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const { createHash } = require('node:crypto');
const { spawn, spawnSync } = require('node:child_process');
const { Transform } = require('node:stream');
const { pipeline, finished } = require('node:stream/promises');
const { createChannel, parseChannel, MAX_CHANNEL_BYTES, MAX_ASSET_BYTES } = require('./channel.cjs');
const BUILDER = 'pavanxs/desktop-builds';
const DOWNLOADS = 'pavanxs/design-editor-downloads';
const SOURCE = Object.freeze({ repository: DOWNLOADS, channel: 'beta' });
const TARGETS = Object.freeze(['darwin-arm64', 'darwin-x64', 'win32-x64']);
const JOBS = Object.freeze(['native (windows-2025, win32, x64)', 'native (macos-15-intel, darwin, x64)', 'native (macos-15, darwin, arm64)']);
const BUILD_STEPS = Object.freeze(['Build and check without printing private build output', 'Stage a private-to-maintainers draft candidate', 'Remove private source and raw logs']);
const ensure = (condition, message) => { if (!condition) throw new Error(message); };
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
function id(value) {
  const text = String(value);
  ensure(/^[1-9]\d{0,15}$/.test(text) && Number.isSafeInteger(Number(text)), 'Invalid GitHub identity.');
  return text;
}
function beta(value) {
  ensure(typeof value === 'string' && value.length <= 80 && value.trim() === value && /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)-beta\.(0|[1-9]\d*)$/.test(value), 'Choose an exact numbered beta version.');
  return value;
}
function compareBeta(a, b) {
  const left = beta(a).replace('-beta.', '.').split('.').map(BigInt);
  const right = beta(b).replace('-beta.', '.').split('.').map(BigInt);
  for (let i = 0; i < left.length; i++) if (left[i] !== right[i]) return left[i] > right[i] ? 1 : -1;
  return 0;
}
function configuration(action, env) {
  ensure(action === 'publish' || action === 'promote', 'Choose publication or promotion.');
  const repository = action === 'publish' ? BUILDER : DOWNLOADS;
  const workflow = action === 'publish' ? 'publish-beta.yml' : 'promote-beta.yml';
  ensure(env.GITHUB_ACTIONS === 'true' && env.RUNNER_ENVIRONMENT === 'github-hosted' && env.GITHUB_REPOSITORY === repository && env.GITHUB_REF === 'refs/heads/main'
    && env.GITHUB_ACTOR === 'pavanxs' && env.GITHUB_TRIGGERING_ACTOR === 'pavanxs'
    && env.GITHUB_WORKFLOW_REF === `${repository}/.github/workflows/${workflow}@refs/heads/main`, 'Only the approved owner workflow on hosted main may release.');
  ensure(env.GITHUB_EVENT_NAME === 'workflow_dispatch' || action === 'publish' && env.GITHUB_EVENT_NAME === 'workflow_run', 'This event cannot release.');
  ensure(env[action === 'publish' ? 'RELEASE_PUBLISH_ENABLED' : 'BETA_PROMOTION_ENABLED'] === 'true', 'This release action is not enabled.');
  return action === 'publish' ? { action, runId: id(env.DE_BUILD_RUN_ID), attempt: id(env.DE_BUILD_ATTEMPT) } : { action, version: beta(env.DE_RELEASE_VERSION) };
}
function validateRun(run, config) {
  ensure(String(run.id) === config.runId && String(run.run_attempt) === config.attempt && run.repository?.full_name === BUILDER
    && run.head_repository?.full_name === BUILDER && run.head_branch === 'main' && /^[a-f0-9]{40}$/.test(run.head_sha || '')
    && run.path === '.github/workflows/native-beta.yml' && run.event === 'workflow_dispatch'
    && run.actor?.login === 'pavanxs' && run.triggering_actor?.login === 'pavanxs'
    && run.status === 'completed' && run.conclusion === 'success', 'The selected native build attempt is not an approved successful run.');
}
function validateJobs(result, config) {
  ensure(Array.isArray(result.jobs) && result.jobs.length === result.total_count && result.jobs.length <= 100, 'The build job list is incomplete.');
  const native = result.jobs.filter(job => job.name?.startsWith('native ('));
  ensure(native.length === JOBS.length && JOBS.every(name => native.filter(job => job.name === name).length === 1), 'All three exact native targets are required.');
  for (const job of native) {
    ensure(String(job.run_id) === config.runId && job.status === 'completed' && job.conclusion === 'success'
      && Array.isArray(job.steps) && BUILD_STEPS.every(name => job.steps.some(step => step.name === name && step.status === 'completed' && step.conclusion === 'success')), 'A native build, draft, or cleanup gate did not pass.');
  }
}
function parseJson(bytes) {
  try { return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); }
  catch { throw new Error('Release metadata is not valid UTF-8 JSON.'); }
}
function inventory(release, names, partial = false) {
  id(release.id);
  ensure(Array.isArray(release.assets) && release.assets.length <= names.length && (partial || release.assets.length === names.length), 'Release asset inventory differs from the allowlist.');
  const seen = new Set(), ids = new Set();
  for (const asset of release.assets) {
    const assetId = id(asset.id);
    ensure(names.includes(asset.name) && !seen.has(asset.name) && !ids.has(assetId) && asset.state === 'uploaded'
      && Number.isSafeInteger(asset.size) && asset.size > 0 && asset.size <= MAX_ASSET_BYTES, 'Unexpected, incomplete, or duplicate release asset.');
    seen.add(asset.name); ids.add(assetId);
  }
  return release.assets;
}
function assetMatches(asset, expected) {
  ensure(asset.name === expected.filename && asset.size === expected.bytes && asset.state === 'uploaded'
    && (!asset.digest || asset.digest === 'sha256:' + expected.sha256), 'Hosted asset metadata differs from the verified bytes.');
}
function candidate(bytes, target, version) {
  const record = parseJson(bytes);
  const keys = ['schemaVersion', 'version', 'platform', 'arch', 'filename', 'bytes', 'sha256', 'nativeLaunch'];
  ensure(record && typeof record === 'object' && Object.keys(record).sort().join() === keys.sort().join()
    && record.schemaVersion === 1 && record.nativeLaunch === true && `${record.platform}-${record.arch}` === target, 'Candidate metadata is outside the public allowlist.');
  beta(record.version);
  ensure(!version || record.version === version, 'Candidate versions do not match.');
  const filename = `design-editor-${record.version}-${target}.${record.platform === 'win32' ? 'zip' : 'tar.gz'}`;
  ensure(record.filename === filename, 'Candidate archive filename does not match its target.');
  // Reuse the same schema and size/checksum rules used by installed beta clients.
  const channel = createChannel({ ...SOURCE, version: record.version, publishedAt: '2026-01-01T00:00:00.000Z', artifacts: [{ platform: record.platform, arch: record.arch, filename, bytes: record.bytes, sha256: record.sha256 }] });
  return { version: record.version, artifact: channel.artifacts[0] };
}
function releaseDocument(bytes, version) {
  const value = parseChannel(new TextDecoder('utf-8', { fatal: true }).decode(bytes), SOURCE);
  ensure(value.version === beta(version) && value.artifacts.length === TARGETS.length
    && TARGETS.every(target => value.artifacts.some(item => `${item.platform}-${item.arch}` === target)), 'Release metadata must contain all three targets for the chosen version.');
  return value;
}
async function findRelease(client, tag) {
  ensure(/^[a-z0-9.-]{1,160}$/.test(tag), 'Invalid release tag.');
  for (let page = 1; page <= 20; page++) {
    const rows = await client.json(`releases?per_page=100&page=${page}`);
    ensure(Array.isArray(rows) && rows.length <= 100, 'Invalid release listing.');
    const matches = rows.filter(row => row.tag_name === tag);
    ensure(matches.length <= 1, 'Duplicate release tag.');
    if (matches.length) {
      const release = await client.json(`releases/${id(matches[0].id)}`);
      ensure(release.tag_name === tag, 'The selected release changed.'); return release;
    }
    if (rows.length < 100) return null;
  }
  throw new Error('Release listing exceeded its bounded lookup.');
}
async function inspectBuild(builder, config) {
  const run = await builder.json(`actions/runs/${config.runId}/attempts/${config.attempt}`); validateRun(run, config);
  validateJobs(await builder.json(`actions/runs/${config.runId}/attempts/${config.attempt}/jobs?per_page=100`), config);
}
async function publicRepository(client) {
  const value = await client.json('');
  ensure(value.full_name === DOWNLOADS && value.private === false && value.default_branch === 'main', 'The approved public downloads repository changed.');
}
async function verifyAssets(client, release, document, metadata, work) {
  const names = [...document.artifacts.map(item => item.filename), 'release.json']; inventory(release, names);
  const manifest = release.assets.find(asset => asset.name === 'release.json');
  const text = await client.assetBytes(manifest, MAX_CHANNEL_BYTES);
  ensure(Buffer.from(text).equals(metadata), 'Published release metadata differs from the verified manifest.');
  for (const expected of document.artifacts) {
    const asset = release.assets.find(item => item.name === expected.filename); assetMatches(asset, expected);
    ensure(asset.browser_download_url === expected.url, 'Hosted release address differs from the schema-1 URL.');
    const destination = path.join(work, 'verify-' + expected.filename);
    await client.download(asset, destination, expected);
    await fsp.unlink(destination);
  }
}
async function publish(config, builder, downloads, work) {
  await inspectBuild(builder, config); await publicRepository(downloads);
  let version;
  const archives = [];
  for (const target of TARGETS) {
    const tag = `candidate-${config.runId}-${config.attempt}-${target}`;
    const release = await findRelease(builder, tag);
    ensure(release?.draft === true, 'A checked candidate draft is missing.');
    ensure(Array.isArray(release.assets) && release.assets.length === 2, 'Candidate draft must contain only its archive and summary.');
    const summary = release.assets.find(asset => asset.name === 'candidate.json');
    ensure(summary, 'Candidate summary is missing.');
    const item = candidate(await builder.assetBytes(summary, MAX_CHANNEL_BYTES), target, version); version = item.version;
    inventory(release, ['candidate.json', item.artifact.filename]);
    const asset = release.assets.find(value => value.name === item.artifact.filename); assetMatches(asset, item.artifact);
    const file = path.join(work, item.artifact.filename);
    await builder.download(asset, file, item.artifact); archives.push({ expected: item.artifact, file });
  }
  const tag = 'v' + version;
  const marker = `Design Editor checked build ${config.runId}/${config.attempt}.`;
  let release = await findRelease(downloads, tag);
  if (!release) {
    const note = version === '0.1.0-beta.4' ? '\n\nKnown beta limitation: an intermittent resize notification remains under investigation.' : '';
    release = await downloads.json('releases', { method: 'POST', data: { tag_name: tag, target_commitish: 'main', name: 'Design Editor ' + version,
      body: `${marker}\n\nUnsigned beta. Operating-system security checks still apply. Publishing this numbered release does not select it for automatic updates.${note}`,
      draft: true, prerelease: true, make_latest: 'false' } });
  }
  ensure(release.tag_name === tag && release.prerelease === true && typeof release.draft === 'boolean' && release.body?.startsWith(marker + '\n'), 'An existing version belongs to a different publication. Nothing was overwritten.');
  const names = [...archives.map(item => item.expected.filename), 'release.json']; inventory(release, names, release.draft);
  let document, metadata;
  const existing = release.assets.find(asset => asset.name === 'release.json');
  if (existing) {
    metadata = Buffer.from(await downloads.assetBytes(existing, MAX_CHANNEL_BYTES)); document = releaseDocument(metadata, version);
    ensure(JSON.stringify(document.artifacts) === JSON.stringify(archives.map(item => item.expected).sort((a, b) => `${a.platform}-${a.arch}`.localeCompare(`${b.platform}-${b.arch}`))), 'The existing version contains different build bytes.');
  } else {
    ensure(release.draft, 'A published version cannot acquire a replacement manifest.');
    ensure(Number.isFinite(Date.parse(release.created_at)), 'Release creation time is missing.');
    document = createChannel({ ...SOURCE, version, publishedAt: new Date(release.created_at).toISOString(), artifacts: archives.map(({ expected: { url, ...item } }) => item) });
    metadata = Buffer.from(JSON.stringify(document, null, 2) + '\n');
  }
  if (release.draft) {
    const manifestFile = path.join(work, 'release.json'); await fsp.writeFile(manifestFile, metadata, { flag: 'wx', mode: 0o600 });
    const files = [...archives, { file: manifestFile, expected: { filename: 'release.json', bytes: metadata.length, sha256: hash(metadata) } }];
    for (const item of files) {
      const hosted = release.assets.find(asset => asset.name === item.expected.filename);
      if (hosted) assetMatches(hosted, item.expected);
      else await downloads.upload(tag, item.file, item.expected);
    }
    release = await downloads.json(`releases/${id(release.id)}`);
    ensure(release.draft === true && release.tag_name === tag && release.body?.startsWith(marker + '\n'), 'The staged release changed during upload.');
  }
  await verifyAssets(downloads, release, document, metadata, work);
  await inspectBuild(builder, config);
  if (release.draft) release = await downloads.json(`releases/${id(release.id)}`, { method: 'PATCH', data: { draft: false, prerelease: true, make_latest: 'false' } });
  ensure(release.draft === false && release.prerelease === true && release.tag_name === tag, 'Release publication needs a fresh state check.');
  // Intentionally no repository-content write in this operation.
  return { version, published: true, feedPromoted: false };
}
function currentFeed(result) {
  ensure(result.type === 'file' && result.path === 'channels/beta.json' && result.encoding === 'base64' && /^[a-f0-9]{40}$/.test(result.sha || '')
    && typeof result.content === 'string' && result.content.length <= 90000 && /^[A-Za-z0-9+/=\r\n]*$/.test(result.content), 'The current feed response is invalid.');
  const bytes = Buffer.from(result.content, 'base64');
  return { sha: result.sha, document: parseChannel(new TextDecoder('utf-8', { fatal: true }).decode(bytes), SOURCE) };
}
async function promote(config, downloads, work) {
  await publicRepository(downloads);
  const before = currentFeed(await downloads.json('contents/channels/beta.json?ref=main'));
  ensure(compareBeta(config.version, before.document.version) >= 0, 'Promotion cannot roll back the update feed.');
  const release = await findRelease(downloads, 'v' + config.version);
  ensure(release?.draft === false && release.prerelease === true, 'Choose an already published numbered beta.');
  ensure(Array.isArray(release.assets) && release.assets.length === 4, 'All three packages and release metadata are required.');
  const manifest = release.assets.find(asset => asset.name === 'release.json'); ensure(manifest, 'Release metadata is missing.');
  const metadata = Buffer.from(await downloads.assetBytes(manifest, MAX_CHANNEL_BYTES));
  const document = releaseDocument(metadata, config.version);
  await verifyAssets(downloads, release, document, metadata, work);
  // Re-read the immutable selection before writing. Concurrent file changes are
  // separately rejected by the Contents API's expected SHA, never overwritten.
  const fresh = await downloads.json(`releases/${id(release.id)}`);
  ensure(fresh.draft === false && fresh.prerelease === true && fresh.tag_name === release.tag_name
    && JSON.stringify(fresh.assets.map(asset => [asset.id, asset.name, asset.size, asset.digest, asset.state]).sort()) === JSON.stringify(release.assets.map(asset => [asset.id, asset.name, asset.size, asset.digest, asset.state]).sort()), 'The release changed during verification.');
  if (before.document.version === config.version) {
    ensure(JSON.stringify(before.document) === JSON.stringify(document), 'The feed already names this version with different metadata.');
    return { version: config.version, promoted: false, alreadySelected: true };
  }
  await downloads.json('contents/channels/beta.json', { method: 'PUT', data: { branch: 'main', sha: before.sha,
    message: 'Promote checked beta ' + config.version, content: metadata.toString('base64') } });
  const after = currentFeed(await downloads.json('contents/channels/beta.json?ref=main'));
  ensure(JSON.stringify(after.document) === JSON.stringify(document), 'Promotion finished with an unexpected feed; inspect it before retrying.');
  return { version: config.version, promoted: true, alreadySelected: false };
}

// GitHub CLI supplies its standard API authentication/HTTPS handling. The token
// is bound to one fixed repository, never passed in argv or printed on failure.
function clientEnvironment(token) {
  ensure(typeof token === 'string' && token.trim().length > 0, 'A scoped repository token is required.');
  const env = { ...process.env };
  for (const key of Object.keys(env)) if (/TOKEN|SECRET|PASSWORD|SSH_KEY|SOURCE_READ_KEY|NODE_OPTIONS|NODE_PATH/i.test(key)) delete env[key];
  return { ...env, GH_TOKEN: token, GH_HOST: 'github.com', GH_PROMPT_DISABLED: '1', GH_DEBUG: '' };
}
function permission(mode, method, resource) {
  if (method === 'GET') return resource === '' || /^releases\?per_page=100&page=([1-9]|1\d|20)$/.test(resource) || /^releases\/\d+$/.test(resource)
    || /^actions\/runs\/\d+\/attempts\/\d+(?:\/jobs\?per_page=100)?$/.test(resource) || resource === 'contents/channels/beta.json?ref=main';
  if (mode === 'publish') return method === 'POST' && resource === 'releases' || method === 'PATCH' && /^releases\/\d+$/.test(resource);
  return mode === 'promote' && method === 'PUT' && resource === 'contents/channels/beta.json';
}
class GitHub {
  constructor(repository, token, mode = 'read', processes = { spawn, spawnSync }) {
    ensure([BUILDER, DOWNLOADS].includes(repository) && ['read', 'publish', 'promote'].includes(mode) && (repository === DOWNLOADS || mode === 'read'), 'Invalid repository capability.');
    this.repository = repository; this.env = clientEnvironment(token); this.mode = mode; this.processes = processes;
  }
  run(args, options = {}) {
    const result = this.processes.spawnSync('gh', args, { env: this.env, shell: false, windowsHide: true, encoding: options.binary ? null : 'utf8',
      input: options.data === undefined ? undefined : JSON.stringify(options.data), timeout: options.timeout || 30000, maxBuffer: options.limit || 2 * 1024 * 1024 });
    ensure(result.status === 0 && !result.error, 'GitHub operation failed. Check permissions and remote state.');
    return result.stdout;
  }
  async json(resource, { method = 'GET', data } = {}) {
    ensure(permission(this.mode, method, resource), 'This action cannot write that GitHub resource.');
    const args = ['api', 'repos/' + this.repository + (resource ? '/' + resource : ''), '--method', method, '-H', 'Accept: application/vnd.github+json'];
    if (data !== undefined) args.push('--input', '-');
    const output = this.run(args, { data });
    try { return JSON.parse(output); } catch { throw new Error('GitHub returned invalid metadata.'); }
  }
  async assetBytes(asset, maximum) {
    id(asset?.id);
    ensure(asset.state === 'uploaded' && Number.isSafeInteger(asset.size) && asset.size > 0 && asset.size <= maximum && maximum <= MAX_CHANNEL_BYTES, 'Release metadata exceeds its size budget.');
    const bytes = this.run(['api', `repos/${this.repository}/releases/assets/${id(asset.id)}`, '-H', 'Accept: application/octet-stream'], { binary: true, limit: maximum + 1024 });
    ensure(bytes.length === asset.size && (!asset.digest || asset.digest === 'sha256:' + hash(bytes)), 'Release metadata download failed integrity checks.');
    return bytes;
  }
  async download(asset, destination, expected) {
    id(asset.id); assetMatches(asset, expected);
    ensure(Number.isSafeInteger(expected.bytes) && expected.bytes > 0 && expected.bytes <= MAX_ASSET_BYTES && /^[a-f0-9]{64}$/.test(expected.sha256), 'Invalid archive transfer budget.');
    const space = await fsp.statfs(path.dirname(destination));
    ensure(space.bavail * space.bsize >= expected.bytes + 64 * 1024 * 1024, 'Insufficient space for a bounded asset transfer.');
    const fd = fs.openSync(destination, 'wx', 0o600), output = fs.createWriteStream(destination, { fd });
    let child, timer, exit = Promise.resolve();
    let bytes = 0, complete = false; const digest = createHash('sha256');
    const counter = new Transform({ transform(chunk, encoding, done) { bytes += chunk.length;
      if (bytes > expected.bytes) done(new Error('Asset exceeded its transfer budget.')); else { digest.update(chunk); done(null, chunk); } } });
    try {
      child = this.processes.spawn('gh', ['api', `repos/${this.repository}/releases/assets/${id(asset.id)}`, '-H', 'Accept: application/octet-stream'], { env: this.env, shell: false, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
      child.stderr.resume();
      exit = new Promise((resolve, reject) => { child.once('error', () => reject(new Error('Asset download could not start.'))); child.once('exit', code => code === 0 ? resolve() : reject(new Error('Asset download failed.'))); });
      timer = setTimeout(() => child.kill(), 10 * 60000);
      await Promise.all([pipeline(child.stdout, counter, output), exit]);
      ensure(bytes === expected.bytes && digest.digest('hex') === expected.sha256, 'Asset bytes do not match the checked candidate.');
      complete = true;
    } finally {
      clearTimeout(timer);
      if (!complete) { child?.kill(); output.destroy(); await finished(output).catch(() => {}); await exit.catch(() => {}); await fsp.rm(destination, { force: true }); }
    }
  }
  async upload(tag, file, expected) {
    ensure(this.mode === 'publish' && this.repository === DOWNLOADS && /^v\d+\.\d+\.\d+-beta\.\d+$/.test(tag) && path.basename(file) === expected.filename, 'This client cannot upload that release asset.');
    const stat = await fsp.lstat(file); ensure(stat.isFile() && !stat.isSymbolicLink() && stat.size === expected.bytes, 'Local verified asset changed before upload.');
    const digest = createHash('sha256'); for await (const chunk of fs.createReadStream(file)) digest.update(chunk);
    ensure(digest.digest('hex') === expected.sha256, 'Local asset checksum changed before upload.');
    this.run(['release', 'upload', tag, file, '--repo', DOWNLOADS], { timeout: 10 * 60000 });
  }
}
async function main(action, env = process.env) {
  const config = configuration(action, env);
  ensure(env.GH_TOKEN && (action !== 'publish' || env.DOWNLOADS_PUBLISH_TOKEN), 'Configure the required scoped token without putting it in source or logs.');
  const work = await fsp.mkdtemp(path.join(os.tmpdir(), 'design-editor-release-'));
  try {
    const result = action === 'publish'
      ? await publish(config, new GitHub(BUILDER, env.GH_TOKEN), new GitHub(DOWNLOADS, env.DOWNLOADS_PUBLISH_TOKEN, 'publish'), work)
      : await promote(config, new GitHub(DOWNLOADS, env.GH_TOKEN, 'promote'), work);
    console.log(JSON.stringify(result));
  } finally { await fsp.rm(work, { recursive: true, force: true }); }
}
if (require.main === module) {
  if (process.argv.length !== 3) { console.error('Choose one fixed release action.'); process.exitCode = 1; }
  else main(process.argv[2]).catch(() => { console.error('Release automation did not finish. Inspect the workflow permissions and public state before retrying.'); process.exitCode = 1; });
}
module.exports = { BUILDER, DOWNLOADS, TARGETS, JOBS, BUILD_STEPS, configuration, validateRun, validateJobs, candidate, releaseDocument, compareBeta, currentFeed, permission, findRelease, publish, promote, GitHub };
