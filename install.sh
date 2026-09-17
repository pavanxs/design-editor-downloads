#!/bin/bash
# Generated for the unsigned beta. macOS security checks remain enabled.
# This template is not a live public installation command.
(
  set -euo pipefail
  umask 077
  [[ "$(/usr/bin/uname -s)" == Darwin ]] || { printf '%s\n' 'This installer supports macOS only.' >&2; exit 1; }
  [[ "${EUID:-$(/usr/bin/id -u)}" -ne 0 ]] || { printf '%s\n' 'Run this installer as your normal user, without sudo.' >&2; exit 1; }
  arch="$(/usr/bin/uname -m)"
  # An Intel shell under Rosetta must still select the native Apple Silicon build.
  if [[ "$arch" == arm64 || "$(/usr/sbin/sysctl -in sysctl.proc_translated 2>/dev/null || true)" == 1 ]]; then
    arch=arm64; sha='8c039d59f2fec6195e4281ad5b0d02b9a940897b4df7b849c6fb48be6787bba6'
  elif [[ "$arch" == x86_64 ]]; then
    arch=x64; sha='527f0578d9812e7dfa225121bda0b1546a6a0e4b5f556295fc8299c272de5fbf'
  else
    printf '%s\n' 'This Mac architecture is not supported.' >&2; exit 1
  fi
  work="$(/usr/bin/mktemp -d /private/tmp/design-editor-bootstrap.XXXXXXXX)"
  cleanup() { [[ -n "$work" && "$work" == /private/tmp/design-editor-bootstrap.* ]] && /bin/rm -rf "$work"; }
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  printf '%s\n' 'Preparing Design Editor. macOS security checks still apply to this beta.'
  name="node-v24.13.1-darwin-$arch"
  /usr/bin/curl --disable --fail --silent --show-error --proto '=https' --tlsv1.2 \
    --connect-timeout 15 --max-time 300 --max-filesize 83886080 \
    --output "$work/node.tar.gz" "https://nodejs.org/dist/v24.13.1/$name.tar.gz"
  printf '%s  %s\n' "$sha" "$work/node.tar.gz" | /usr/bin/shasum -a 256 -c - >/dev/null
  # Only these exact files are extracted from the pinned, checksum-checked archive.
  /usr/bin/tar -xzf "$work/node.tar.gz" -C "$work" "$name/bin/node" "$name/LICENSE"
  unset NODE_OPTIONS NODE_PATH ELECTRON_RUN_AS_NODE ELECTRON_OVERRIDE_DIST_PATH
  /bin/cat > "$work/mac-runtime.cjs" <<'DESIGN_EDITOR_RUNTIME_2f5499313378e130b8f69c27d3402a5498826a055972863c47011aa297b6bd5e'
"use strict";
var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// channel.cjs
var require_channel = __commonJS({
  "channel.cjs"(exports2, module2) {
    "use strict";
    var MAX_CHANNEL_BYTES = 64 * 1024;
    var MAX_ASSET_BYTES = 2 ** 31 - 1;
    var TARGETS = /* @__PURE__ */ new Set(["win32-x64", "win32-arm64", "darwin-x64", "darwin-arm64"]);
    var CHANNELS = /* @__PURE__ */ new Set(["beta", "stable"]);
    var ROOT_KEYS = ["schemaVersion", "product", "repository", "channel", "version", "publishedAt", "artifacts"];
    var ARTIFACT_KEYS = ["platform", "arch", "filename", "bytes", "sha256", "url"];
    function exactObject(value, keys, label) {
      if (!value || typeof value !== "object" || Array.isArray(value) || ![Object.prototype, null].includes(Object.getPrototypeOf(value))) {
        throw new Error(`${label} must be a plain object.`);
      }
      const own = Reflect.ownKeys(value);
      if (own.length !== keys.length || keys.some((key) => !Object.hasOwn(value, key)) || own.some((key) => typeof key !== "string" || !keys.includes(key))) {
        throw new Error(`${label} has missing or unexpected fields.`);
      }
      if (own.some((key) => !Object.hasOwn(Object.getOwnPropertyDescriptor(value, key), "value"))) {
        throw new Error(`${label} must contain data, not getters or setters.`);
      }
    }
    function repositoryName(value) {
      if (typeof value !== "string" || value.length > 140 || value.trim() !== value || !/^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?\/[A-Za-z0-9][A-Za-z0-9._-]{0,99}$/.test(value)) {
        throw new Error("Configure a GitHub downloads repository as owner/name.");
      }
      return value;
    }
    function channelName(value) {
      if (!CHANNELS.has(value)) throw new Error("Release channel must be beta or stable.");
      return value;
    }
    function releaseVersion2(value, channel) {
      if (typeof value !== "string" || value.length > 96 || value.trim() !== value || !/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/.test(value)) {
        throw new Error("Use an exact release version, for example 0.1.0-beta.1.");
      }
      const suffix = value.includes("-") ? value.slice(value.indexOf("-") + 1) : "";
      if (suffix.split(".").some((part) => /^\d+$/.test(part) && part.length > 1 && part.startsWith("0"))) {
        throw new Error("Numeric prerelease identifiers must not have leading zeros.");
      }
      if (channel === "stable" && suffix) throw new Error("A stable channel cannot select a prerelease version.");
      return value;
    }
    function timestamp(value) {
      if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(value) || !Number.isFinite(Date.parse(value)) || new Date(value).toISOString() !== value) {
        throw new Error("publishedAt must be a valid UTC ISO timestamp with milliseconds.");
      }
      return value;
    }
    function checkedArtifact(value, repository, version, withUrl) {
      exactObject(value, withUrl ? ARTIFACT_KEYS : ARTIFACT_KEYS.filter((key) => key !== "url"), "Release artifact");
      const { platform, arch, filename, bytes, sha256 } = value;
      if (typeof platform !== "string" || typeof arch !== "string" || !TARGETS.has(`${platform}-${arch}`)) {
        throw new Error("Release artifact must specify a Windows or macOS x64/arm64 target.");
      }
      const stem = `design-editor-${version}-${platform}-${arch}`;
      if (filename !== `${stem}.zip` && !(platform === "darwin" && filename === `${stem}.tar.gz`)) {
        throw new Error("Artifact filename must match its version, platform, architecture and archive type.");
      }
      if (!Number.isSafeInteger(bytes) || bytes <= 0 || bytes > MAX_ASSET_BYTES) {
        throw new Error("Artifact byte count must be positive and below 2 GiB.");
      }
      if (typeof sha256 !== "string" || sha256.length !== 64 || !/^[a-f0-9]{64}$/.test(sha256)) {
        throw new Error("Artifact SHA-256 must contain 64 lowercase hexadecimal characters.");
      }
      const url = `https://github.com/${repository}/releases/download/v${version}/${filename}`;
      if (withUrl && value.url !== url) throw new Error("Artifact URL does not match the configured downloads repository and release.");
      return Object.freeze({ platform, arch, filename, bytes, sha256, url });
    }
    function checkedArtifacts(values, repository, version, withUrl) {
      if (!Array.isArray(values) || values.length < 1 || values.length > TARGETS.size) {
        throw new Error("List one to four actual release artifacts; do not invent missing builds.");
      }
      for (let index = 0; index < values.length; index++) {
        if (!Object.hasOwn(values, index)) throw new Error("Release artifact list must not contain empty slots.");
      }
      const seen = /* @__PURE__ */ new Set();
      const artifacts = values.map((value) => {
        const artifact = checkedArtifact(value, repository, version, withUrl);
        const target = `${artifact.platform}-${artifact.arch}`;
        if (seen.has(target)) throw new Error("Release contains duplicate platform/architecture targets.");
        seen.add(target);
        return artifact;
      });
      artifacts.sort((a, b) => `${a.platform}-${a.arch}` < `${b.platform}-${b.arch}` ? -1 : 1);
      return Object.freeze(artifacts);
    }
    function createChannel(input) {
      exactObject(input, ["repository", "channel", "version", "publishedAt", "artifacts"], "Release input");
      const repository = repositoryName(input.repository);
      const channel = channelName(input.channel);
      const version = releaseVersion2(input.version, channel);
      return Object.freeze({
        schemaVersion: 1,
        product: "design-editor",
        repository,
        channel,
        version,
        publishedAt: timestamp(input.publishedAt),
        artifacts: checkedArtifacts(input.artifacts, repository, version, false)
      });
    }
    function validateChannel(value, expected) {
      exactObject(expected, ["repository", "channel"], "Expected release source");
      const repository = repositoryName(expected.repository);
      const channel = channelName(expected.channel);
      exactObject(value, ROOT_KEYS, "Channel document");
      if (value.schemaVersion !== 1 || value.product !== "design-editor") {
        throw new Error("Unsupported release schema or product.");
      }
      if (value.repository !== repository || value.channel !== channel) {
        throw new Error("Channel does not match the configured release source.");
      }
      const version = releaseVersion2(value.version, channel);
      return Object.freeze({
        schemaVersion: 1,
        product: "design-editor",
        repository,
        channel,
        version,
        publishedAt: timestamp(value.publishedAt),
        artifacts: checkedArtifacts(value.artifacts, repository, version, true)
      });
    }
    function parseChannel(text, expected) {
      if (typeof text !== "string" || Buffer.byteLength(text, "utf8") > MAX_CHANNEL_BYTES) {
        throw new Error("Channel JSON must be text within the 64 KiB limit.");
      }
      let value;
      try {
        value = JSON.parse(text);
      } catch {
        throw new Error("Release metadata is not valid JSON.");
      }
      return validateChannel(value, expected);
    }
    function selectArtifact2(document, target, expected) {
      exactObject(target, ["platform", "arch"], "Requested target");
      const channel = validateChannel(document, expected);
      return channel.artifacts.find((item) => item.platform === target.platform && item.arch === target.arch) || null;
    }
    module2.exports = { createChannel, validateChannel, parseChannel, selectArtifact: selectArtifact2, releaseVersion: releaseVersion2, MAX_CHANNEL_BYTES, MAX_ASSET_BYTES };
  }
});

// ../../../node_modules/@isaacs/fs-minipass/node_modules/minipass/dist/commonjs/index.js
var require_commonjs = __commonJS({
  "../../../node_modules/@isaacs/fs-minipass/node_modules/minipass/dist/commonjs/index.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.Minipass = exports2.isWritable = exports2.isReadable = exports2.isStream = void 0;
    var proc = typeof process === "object" && process ? process : {
      stdout: null,
      stderr: null
    };
    var node_events_1 = require("node:events");
    var node_stream_1 = __importDefault(require("node:stream"));
    var node_string_decoder_1 = require("node:string_decoder");
    var isStream = (s) => !!s && typeof s === "object" && (s instanceof Minipass || s instanceof node_stream_1.default || (0, exports2.isReadable)(s) || (0, exports2.isWritable)(s));
    exports2.isStream = isStream;
    var isReadable = (s) => !!s && typeof s === "object" && s instanceof node_events_1.EventEmitter && typeof s.pipe === "function" && // node core Writable streams have a pipe() method, but it throws
    s.pipe !== node_stream_1.default.Writable.prototype.pipe;
    exports2.isReadable = isReadable;
    var isWritable = (s) => !!s && typeof s === "object" && s instanceof node_events_1.EventEmitter && typeof s.write === "function" && typeof s.end === "function";
    exports2.isWritable = isWritable;
    var EOF = /* @__PURE__ */ Symbol("EOF");
    var MAYBE_EMIT_END = /* @__PURE__ */ Symbol("maybeEmitEnd");
    var EMITTED_END = /* @__PURE__ */ Symbol("emittedEnd");
    var EMITTING_END = /* @__PURE__ */ Symbol("emittingEnd");
    var EMITTED_ERROR = /* @__PURE__ */ Symbol("emittedError");
    var CLOSED = /* @__PURE__ */ Symbol("closed");
    var READ = /* @__PURE__ */ Symbol("read");
    var FLUSH = /* @__PURE__ */ Symbol("flush");
    var FLUSHCHUNK = /* @__PURE__ */ Symbol("flushChunk");
    var ENCODING = /* @__PURE__ */ Symbol("encoding");
    var DECODER = /* @__PURE__ */ Symbol("decoder");
    var FLOWING = /* @__PURE__ */ Symbol("flowing");
    var PAUSED = /* @__PURE__ */ Symbol("paused");
    var RESUME = /* @__PURE__ */ Symbol("resume");
    var BUFFER = /* @__PURE__ */ Symbol("buffer");
    var PIPES = /* @__PURE__ */ Symbol("pipes");
    var BUFFERLENGTH = /* @__PURE__ */ Symbol("bufferLength");
    var BUFFERPUSH = /* @__PURE__ */ Symbol("bufferPush");
    var BUFFERSHIFT = /* @__PURE__ */ Symbol("bufferShift");
    var OBJECTMODE = /* @__PURE__ */ Symbol("objectMode");
    var DESTROYED = /* @__PURE__ */ Symbol("destroyed");
    var ERROR = /* @__PURE__ */ Symbol("error");
    var EMITDATA = /* @__PURE__ */ Symbol("emitData");
    var EMITEND = /* @__PURE__ */ Symbol("emitEnd");
    var EMITEND2 = /* @__PURE__ */ Symbol("emitEnd2");
    var ASYNC = /* @__PURE__ */ Symbol("async");
    var ABORT = /* @__PURE__ */ Symbol("abort");
    var ABORTED = /* @__PURE__ */ Symbol("aborted");
    var SIGNAL = /* @__PURE__ */ Symbol("signal");
    var DATALISTENERS = /* @__PURE__ */ Symbol("dataListeners");
    var DISCARDED = /* @__PURE__ */ Symbol("discarded");
    var defer = (fn) => Promise.resolve().then(fn);
    var nodefer = (fn) => fn();
    var isEndish = (ev) => ev === "end" || ev === "finish" || ev === "prefinish";
    var isArrayBufferLike = (b) => b instanceof ArrayBuffer || !!b && typeof b === "object" && b.constructor && b.constructor.name === "ArrayBuffer" && b.byteLength >= 0;
    var isArrayBufferView = (b) => !Buffer.isBuffer(b) && ArrayBuffer.isView(b);
    var Pipe = class {
      src;
      dest;
      opts;
      ondrain;
      constructor(src, dest, opts) {
        this.src = src;
        this.dest = dest;
        this.opts = opts;
        this.ondrain = () => src[RESUME]();
        this.dest.on("drain", this.ondrain);
      }
      unpipe() {
        this.dest.removeListener("drain", this.ondrain);
      }
      // only here for the prototype
      /* c8 ignore start */
      proxyErrors(_er) {
      }
      /* c8 ignore stop */
      end() {
        this.unpipe();
        if (this.opts.end)
          this.dest.end();
      }
    };
    var PipeProxyErrors = class extends Pipe {
      unpipe() {
        this.src.removeListener("error", this.proxyErrors);
        super.unpipe();
      }
      constructor(src, dest, opts) {
        super(src, dest, opts);
        this.proxyErrors = (er) => this.dest.emit("error", er);
        src.on("error", this.proxyErrors);
      }
    };
    var isObjectModeOptions = (o) => !!o.objectMode;
    var isEncodingOptions = (o) => !o.objectMode && !!o.encoding && o.encoding !== "buffer";
    var Minipass = class extends node_events_1.EventEmitter {
      [FLOWING] = false;
      [PAUSED] = false;
      [PIPES] = [];
      [BUFFER] = [];
      [OBJECTMODE];
      [ENCODING];
      [ASYNC];
      [DECODER];
      [EOF] = false;
      [EMITTED_END] = false;
      [EMITTING_END] = false;
      [CLOSED] = false;
      [EMITTED_ERROR] = null;
      [BUFFERLENGTH] = 0;
      [DESTROYED] = false;
      [SIGNAL];
      [ABORTED] = false;
      [DATALISTENERS] = 0;
      [DISCARDED] = false;
      /**
       * true if the stream can be written
       */
      writable = true;
      /**
       * true if the stream can be read
       */
      readable = true;
      /**
       * If `RType` is Buffer, then options do not need to be provided.
       * Otherwise, an options object must be provided to specify either
       * {@link Minipass.SharedOptions.objectMode} or
       * {@link Minipass.SharedOptions.encoding}, as appropriate.
       */
      constructor(...args) {
        const options = args[0] || {};
        super();
        if (options.objectMode && typeof options.encoding === "string") {
          throw new TypeError("Encoding and objectMode may not be used together");
        }
        if (isObjectModeOptions(options)) {
          this[OBJECTMODE] = true;
          this[ENCODING] = null;
        } else if (isEncodingOptions(options)) {
          this[ENCODING] = options.encoding;
          this[OBJECTMODE] = false;
        } else {
          this[OBJECTMODE] = false;
          this[ENCODING] = null;
        }
        this[ASYNC] = !!options.async;
        this[DECODER] = this[ENCODING] ? new node_string_decoder_1.StringDecoder(this[ENCODING]) : null;
        if (options && options.debugExposeBuffer === true) {
          Object.defineProperty(this, "buffer", { get: () => this[BUFFER] });
        }
        if (options && options.debugExposePipes === true) {
          Object.defineProperty(this, "pipes", { get: () => this[PIPES] });
        }
        const { signal } = options;
        if (signal) {
          this[SIGNAL] = signal;
          if (signal.aborted) {
            this[ABORT]();
          } else {
            signal.addEventListener("abort", () => this[ABORT]());
          }
        }
      }
      /**
       * The amount of data stored in the buffer waiting to be read.
       *
       * For Buffer strings, this will be the total byte length.
       * For string encoding streams, this will be the string character length,
       * according to JavaScript's `string.length` logic.
       * For objectMode streams, this is a count of the items waiting to be
       * emitted.
       */
      get bufferLength() {
        return this[BUFFERLENGTH];
      }
      /**
       * The `BufferEncoding` currently in use, or `null`
       */
      get encoding() {
        return this[ENCODING];
      }
      /**
       * @deprecated - This is a read only property
       */
      set encoding(_enc) {
        throw new Error("Encoding must be set at instantiation time");
      }
      /**
       * @deprecated - Encoding may only be set at instantiation time
       */
      setEncoding(_enc) {
        throw new Error("Encoding must be set at instantiation time");
      }
      /**
       * True if this is an objectMode stream
       */
      get objectMode() {
        return this[OBJECTMODE];
      }
      /**
       * @deprecated - This is a read-only property
       */
      set objectMode(_om) {
        throw new Error("objectMode must be set at instantiation time");
      }
      /**
       * true if this is an async stream
       */
      get ["async"]() {
        return this[ASYNC];
      }
      /**
       * Set to true to make this stream async.
       *
       * Once set, it cannot be unset, as this would potentially cause incorrect
       * behavior.  Ie, a sync stream can be made async, but an async stream
       * cannot be safely made sync.
       */
      set ["async"](a) {
        this[ASYNC] = this[ASYNC] || !!a;
      }
      // drop everything and get out of the flow completely
      [ABORT]() {
        this[ABORTED] = true;
        this.emit("abort", this[SIGNAL]?.reason);
        this.destroy(this[SIGNAL]?.reason);
      }
      /**
       * True if the stream has been aborted.
       */
      get aborted() {
        return this[ABORTED];
      }
      /**
       * No-op setter. Stream aborted status is set via the AbortSignal provided
       * in the constructor options.
       */
      set aborted(_) {
      }
      write(chunk, encoding, cb) {
        if (this[ABORTED])
          return false;
        if (this[EOF])
          throw new Error("write after end");
        if (this[DESTROYED]) {
          this.emit("error", Object.assign(new Error("Cannot call write after a stream was destroyed"), { code: "ERR_STREAM_DESTROYED" }));
          return true;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = "utf8";
        }
        if (!encoding)
          encoding = "utf8";
        const fn = this[ASYNC] ? defer : nodefer;
        if (!this[OBJECTMODE] && !Buffer.isBuffer(chunk)) {
          if (isArrayBufferView(chunk)) {
            chunk = Buffer.from(chunk.buffer, chunk.byteOffset, chunk.byteLength);
          } else if (isArrayBufferLike(chunk)) {
            chunk = Buffer.from(chunk);
          } else if (typeof chunk !== "string") {
            throw new Error("Non-contiguous data written to non-objectMode stream");
          }
        }
        if (this[OBJECTMODE]) {
          if (this[FLOWING] && this[BUFFERLENGTH] !== 0)
            this[FLUSH](true);
          if (this[FLOWING])
            this.emit("data", chunk);
          else
            this[BUFFERPUSH](chunk);
          if (this[BUFFERLENGTH] !== 0)
            this.emit("readable");
          if (cb)
            fn(cb);
          return this[FLOWING];
        }
        if (!chunk.length) {
          if (this[BUFFERLENGTH] !== 0)
            this.emit("readable");
          if (cb)
            fn(cb);
          return this[FLOWING];
        }
        if (typeof chunk === "string" && // unless it is a string already ready for us to use
        !(encoding === this[ENCODING] && !this[DECODER]?.lastNeed)) {
          chunk = Buffer.from(chunk, encoding);
        }
        if (Buffer.isBuffer(chunk) && this[ENCODING]) {
          chunk = this[DECODER].write(chunk);
        }
        if (this[FLOWING] && this[BUFFERLENGTH] !== 0)
          this[FLUSH](true);
        if (this[FLOWING])
          this.emit("data", chunk);
        else
          this[BUFFERPUSH](chunk);
        if (this[BUFFERLENGTH] !== 0)
          this.emit("readable");
        if (cb)
          fn(cb);
        return this[FLOWING];
      }
      /**
       * Low-level explicit read method.
       *
       * In objectMode, the argument is ignored, and one item is returned if
       * available.
       *
       * `n` is the number of bytes (or in the case of encoding streams,
       * characters) to consume. If `n` is not provided, then the entire buffer
       * is returned, or `null` is returned if no data is available.
       *
       * If `n` is greater that the amount of data in the internal buffer,
       * then `null` is returned.
       */
      read(n) {
        if (this[DESTROYED])
          return null;
        this[DISCARDED] = false;
        if (this[BUFFERLENGTH] === 0 || n === 0 || n && n > this[BUFFERLENGTH]) {
          this[MAYBE_EMIT_END]();
          return null;
        }
        if (this[OBJECTMODE])
          n = null;
        if (this[BUFFER].length > 1 && !this[OBJECTMODE]) {
          this[BUFFER] = [
            this[ENCODING] ? this[BUFFER].join("") : Buffer.concat(this[BUFFER], this[BUFFERLENGTH])
          ];
        }
        const ret = this[READ](n || null, this[BUFFER][0]);
        this[MAYBE_EMIT_END]();
        return ret;
      }
      [READ](n, chunk) {
        if (this[OBJECTMODE])
          this[BUFFERSHIFT]();
        else {
          const c = chunk;
          if (n === c.length || n === null)
            this[BUFFERSHIFT]();
          else if (typeof c === "string") {
            this[BUFFER][0] = c.slice(n);
            chunk = c.slice(0, n);
            this[BUFFERLENGTH] -= n;
          } else {
            this[BUFFER][0] = c.subarray(n);
            chunk = c.subarray(0, n);
            this[BUFFERLENGTH] -= n;
          }
        }
        this.emit("data", chunk);
        if (!this[BUFFER].length && !this[EOF])
          this.emit("drain");
        return chunk;
      }
      end(chunk, encoding, cb) {
        if (typeof chunk === "function") {
          cb = chunk;
          chunk = void 0;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = "utf8";
        }
        if (chunk !== void 0)
          this.write(chunk, encoding);
        if (cb)
          this.once("end", cb);
        this[EOF] = true;
        this.writable = false;
        if (this[FLOWING] || !this[PAUSED])
          this[MAYBE_EMIT_END]();
        return this;
      }
      // don't let the internal resume be overwritten
      [RESUME]() {
        if (this[DESTROYED])
          return;
        if (!this[DATALISTENERS] && !this[PIPES].length) {
          this[DISCARDED] = true;
        }
        this[PAUSED] = false;
        this[FLOWING] = true;
        this.emit("resume");
        if (this[BUFFER].length)
          this[FLUSH]();
        else if (this[EOF])
          this[MAYBE_EMIT_END]();
        else
          this.emit("drain");
      }
      /**
       * Resume the stream if it is currently in a paused state
       *
       * If called when there are no pipe destinations or `data` event listeners,
       * this will place the stream in a "discarded" state, where all data will
       * be thrown away. The discarded state is removed if a pipe destination or
       * data handler is added, if pause() is called, or if any synchronous or
       * asynchronous iteration is started.
       */
      resume() {
        return this[RESUME]();
      }
      /**
       * Pause the stream
       */
      pause() {
        this[FLOWING] = false;
        this[PAUSED] = true;
        this[DISCARDED] = false;
      }
      /**
       * true if the stream has been forcibly destroyed
       */
      get destroyed() {
        return this[DESTROYED];
      }
      /**
       * true if the stream is currently in a flowing state, meaning that
       * any writes will be immediately emitted.
       */
      get flowing() {
        return this[FLOWING];
      }
      /**
       * true if the stream is currently in a paused state
       */
      get paused() {
        return this[PAUSED];
      }
      [BUFFERPUSH](chunk) {
        if (this[OBJECTMODE])
          this[BUFFERLENGTH] += 1;
        else
          this[BUFFERLENGTH] += chunk.length;
        this[BUFFER].push(chunk);
      }
      [BUFFERSHIFT]() {
        if (this[OBJECTMODE])
          this[BUFFERLENGTH] -= 1;
        else
          this[BUFFERLENGTH] -= this[BUFFER][0].length;
        return this[BUFFER].shift();
      }
      [FLUSH](noDrain = false) {
        do {
        } while (this[FLUSHCHUNK](this[BUFFERSHIFT]()) && this[BUFFER].length);
        if (!noDrain && !this[BUFFER].length && !this[EOF])
          this.emit("drain");
      }
      [FLUSHCHUNK](chunk) {
        this.emit("data", chunk);
        return this[FLOWING];
      }
      /**
       * Pipe all data emitted by this stream into the destination provided.
       *
       * Triggers the flow of data.
       */
      pipe(dest, opts) {
        if (this[DESTROYED])
          return dest;
        this[DISCARDED] = false;
        const ended = this[EMITTED_END];
        opts = opts || {};
        if (dest === proc.stdout || dest === proc.stderr)
          opts.end = false;
        else
          opts.end = opts.end !== false;
        opts.proxyErrors = !!opts.proxyErrors;
        if (ended) {
          if (opts.end)
            dest.end();
        } else {
          this[PIPES].push(!opts.proxyErrors ? new Pipe(this, dest, opts) : new PipeProxyErrors(this, dest, opts));
          if (this[ASYNC])
            defer(() => this[RESUME]());
          else
            this[RESUME]();
        }
        return dest;
      }
      /**
       * Fully unhook a piped destination stream.
       *
       * If the destination stream was the only consumer of this stream (ie,
       * there are no other piped destinations or `'data'` event listeners)
       * then the flow of data will stop until there is another consumer or
       * {@link Minipass#resume} is explicitly called.
       */
      unpipe(dest) {
        const p = this[PIPES].find((p2) => p2.dest === dest);
        if (p) {
          if (this[PIPES].length === 1) {
            if (this[FLOWING] && this[DATALISTENERS] === 0) {
              this[FLOWING] = false;
            }
            this[PIPES] = [];
          } else
            this[PIPES].splice(this[PIPES].indexOf(p), 1);
          p.unpipe();
        }
      }
      /**
       * Alias for {@link Minipass#on}
       */
      addListener(ev, handler) {
        return this.on(ev, handler);
      }
      /**
       * Mostly identical to `EventEmitter.on`, with the following
       * behavior differences to prevent data loss and unnecessary hangs:
       *
       * - Adding a 'data' event handler will trigger the flow of data
       *
       * - Adding a 'readable' event handler when there is data waiting to be read
       *   will cause 'readable' to be emitted immediately.
       *
       * - Adding an 'endish' event handler ('end', 'finish', etc.) which has
       *   already passed will cause the event to be emitted immediately and all
       *   handlers removed.
       *
       * - Adding an 'error' event handler after an error has been emitted will
       *   cause the event to be re-emitted immediately with the error previously
       *   raised.
       */
      on(ev, handler) {
        const ret = super.on(ev, handler);
        if (ev === "data") {
          this[DISCARDED] = false;
          this[DATALISTENERS]++;
          if (!this[PIPES].length && !this[FLOWING]) {
            this[RESUME]();
          }
        } else if (ev === "readable" && this[BUFFERLENGTH] !== 0) {
          super.emit("readable");
        } else if (isEndish(ev) && this[EMITTED_END]) {
          super.emit(ev);
          this.removeAllListeners(ev);
        } else if (ev === "error" && this[EMITTED_ERROR]) {
          const h = handler;
          if (this[ASYNC])
            defer(() => h.call(this, this[EMITTED_ERROR]));
          else
            h.call(this, this[EMITTED_ERROR]);
        }
        return ret;
      }
      /**
       * Alias for {@link Minipass#off}
       */
      removeListener(ev, handler) {
        return this.off(ev, handler);
      }
      /**
       * Mostly identical to `EventEmitter.off`
       *
       * If a 'data' event handler is removed, and it was the last consumer
       * (ie, there are no pipe destinations or other 'data' event listeners),
       * then the flow of data will stop until there is another consumer or
       * {@link Minipass#resume} is explicitly called.
       */
      off(ev, handler) {
        const ret = super.off(ev, handler);
        if (ev === "data") {
          this[DATALISTENERS] = this.listeners("data").length;
          if (this[DATALISTENERS] === 0 && !this[DISCARDED] && !this[PIPES].length) {
            this[FLOWING] = false;
          }
        }
        return ret;
      }
      /**
       * Mostly identical to `EventEmitter.removeAllListeners`
       *
       * If all 'data' event handlers are removed, and they were the last consumer
       * (ie, there are no pipe destinations), then the flow of data will stop
       * until there is another consumer or {@link Minipass#resume} is explicitly
       * called.
       */
      removeAllListeners(ev) {
        const ret = super.removeAllListeners(ev);
        if (ev === "data" || ev === void 0) {
          this[DATALISTENERS] = 0;
          if (!this[DISCARDED] && !this[PIPES].length) {
            this[FLOWING] = false;
          }
        }
        return ret;
      }
      /**
       * true if the 'end' event has been emitted
       */
      get emittedEnd() {
        return this[EMITTED_END];
      }
      [MAYBE_EMIT_END]() {
        if (!this[EMITTING_END] && !this[EMITTED_END] && !this[DESTROYED] && this[BUFFER].length === 0 && this[EOF]) {
          this[EMITTING_END] = true;
          this.emit("end");
          this.emit("prefinish");
          this.emit("finish");
          if (this[CLOSED])
            this.emit("close");
          this[EMITTING_END] = false;
        }
      }
      /**
       * Mostly identical to `EventEmitter.emit`, with the following
       * behavior differences to prevent data loss and unnecessary hangs:
       *
       * If the stream has been destroyed, and the event is something other
       * than 'close' or 'error', then `false` is returned and no handlers
       * are called.
       *
       * If the event is 'end', and has already been emitted, then the event
       * is ignored. If the stream is in a paused or non-flowing state, then
       * the event will be deferred until data flow resumes. If the stream is
       * async, then handlers will be called on the next tick rather than
       * immediately.
       *
       * If the event is 'close', and 'end' has not yet been emitted, then
       * the event will be deferred until after 'end' is emitted.
       *
       * If the event is 'error', and an AbortSignal was provided for the stream,
       * and there are no listeners, then the event is ignored, matching the
       * behavior of node core streams in the presense of an AbortSignal.
       *
       * If the event is 'finish' or 'prefinish', then all listeners will be
       * removed after emitting the event, to prevent double-firing.
       */
      emit(ev, ...args) {
        const data = args[0];
        if (ev !== "error" && ev !== "close" && ev !== DESTROYED && this[DESTROYED]) {
          return false;
        } else if (ev === "data") {
          return !this[OBJECTMODE] && !data ? false : this[ASYNC] ? (defer(() => this[EMITDATA](data)), true) : this[EMITDATA](data);
        } else if (ev === "end") {
          return this[EMITEND]();
        } else if (ev === "close") {
          this[CLOSED] = true;
          if (!this[EMITTED_END] && !this[DESTROYED])
            return false;
          const ret2 = super.emit("close");
          this.removeAllListeners("close");
          return ret2;
        } else if (ev === "error") {
          this[EMITTED_ERROR] = data;
          super.emit(ERROR, data);
          const ret2 = !this[SIGNAL] || this.listeners("error").length ? super.emit("error", data) : false;
          this[MAYBE_EMIT_END]();
          return ret2;
        } else if (ev === "resume") {
          const ret2 = super.emit("resume");
          this[MAYBE_EMIT_END]();
          return ret2;
        } else if (ev === "finish" || ev === "prefinish") {
          const ret2 = super.emit(ev);
          this.removeAllListeners(ev);
          return ret2;
        }
        const ret = super.emit(ev, ...args);
        this[MAYBE_EMIT_END]();
        return ret;
      }
      [EMITDATA](data) {
        for (const p of this[PIPES]) {
          if (p.dest.write(data) === false)
            this.pause();
        }
        const ret = this[DISCARDED] ? false : super.emit("data", data);
        this[MAYBE_EMIT_END]();
        return ret;
      }
      [EMITEND]() {
        if (this[EMITTED_END])
          return false;
        this[EMITTED_END] = true;
        this.readable = false;
        return this[ASYNC] ? (defer(() => this[EMITEND2]()), true) : this[EMITEND2]();
      }
      [EMITEND2]() {
        if (this[DECODER]) {
          const data = this[DECODER].end();
          if (data) {
            for (const p of this[PIPES]) {
              p.dest.write(data);
            }
            if (!this[DISCARDED])
              super.emit("data", data);
          }
        }
        for (const p of this[PIPES]) {
          p.end();
        }
        const ret = super.emit("end");
        this.removeAllListeners("end");
        return ret;
      }
      /**
       * Return a Promise that resolves to an array of all emitted data once
       * the stream ends.
       */
      async collect() {
        const buf = Object.assign([], {
          dataLength: 0
        });
        if (!this[OBJECTMODE])
          buf.dataLength = 0;
        const p = this.promise();
        this.on("data", (c) => {
          buf.push(c);
          if (!this[OBJECTMODE])
            buf.dataLength += c.length;
        });
        await p;
        return buf;
      }
      /**
       * Return a Promise that resolves to the concatenation of all emitted data
       * once the stream ends.
       *
       * Not allowed on objectMode streams.
       */
      async concat() {
        if (this[OBJECTMODE]) {
          throw new Error("cannot concat in objectMode");
        }
        const buf = await this.collect();
        return this[ENCODING] ? buf.join("") : Buffer.concat(buf, buf.dataLength);
      }
      /**
       * Return a void Promise that resolves once the stream ends.
       */
      async promise() {
        return new Promise((resolve, reject) => {
          this.on(DESTROYED, () => reject(new Error("stream destroyed")));
          this.on("error", (er) => reject(er));
          this.on("end", () => resolve());
        });
      }
      /**
       * Asynchronous `for await of` iteration.
       *
       * This will continue emitting all chunks until the stream terminates.
       */
      [Symbol.asyncIterator]() {
        this[DISCARDED] = false;
        let stopped = false;
        const stop = async () => {
          this.pause();
          stopped = true;
          return { value: void 0, done: true };
        };
        const next = () => {
          if (stopped)
            return stop();
          const res = this.read();
          if (res !== null)
            return Promise.resolve({ done: false, value: res });
          if (this[EOF])
            return stop();
          let resolve;
          let reject;
          const onerr = (er) => {
            this.off("data", ondata);
            this.off("end", onend);
            this.off(DESTROYED, ondestroy);
            stop();
            reject(er);
          };
          const ondata = (value) => {
            this.off("error", onerr);
            this.off("end", onend);
            this.off(DESTROYED, ondestroy);
            this.pause();
            resolve({ value, done: !!this[EOF] });
          };
          const onend = () => {
            this.off("error", onerr);
            this.off("data", ondata);
            this.off(DESTROYED, ondestroy);
            stop();
            resolve({ done: true, value: void 0 });
          };
          const ondestroy = () => onerr(new Error("stream destroyed"));
          return new Promise((res2, rej) => {
            reject = rej;
            resolve = res2;
            this.once(DESTROYED, ondestroy);
            this.once("error", onerr);
            this.once("end", onend);
            this.once("data", ondata);
          });
        };
        return {
          next,
          throw: stop,
          return: stop,
          [Symbol.asyncIterator]() {
            return this;
          },
          [Symbol.asyncDispose]: async () => {
          }
        };
      }
      /**
       * Synchronous `for of` iteration.
       *
       * The iteration will terminate when the internal buffer runs out, even
       * if the stream has not yet terminated.
       */
      [Symbol.iterator]() {
        this[DISCARDED] = false;
        let stopped = false;
        const stop = () => {
          this.pause();
          this.off(ERROR, stop);
          this.off(DESTROYED, stop);
          this.off("end", stop);
          stopped = true;
          return { done: true, value: void 0 };
        };
        const next = () => {
          if (stopped)
            return stop();
          const value = this.read();
          return value === null ? stop() : { done: false, value };
        };
        this.once("end", stop);
        this.once(ERROR, stop);
        this.once(DESTROYED, stop);
        return {
          next,
          throw: stop,
          return: stop,
          [Symbol.iterator]() {
            return this;
          },
          [Symbol.dispose]: () => {
          }
        };
      }
      /**
       * Destroy a stream, preventing it from being used for any further purpose.
       *
       * If the stream has a `close()` method, then it will be called on
       * destruction.
       *
       * After destruction, any attempt to write data, read data, or emit most
       * events will be ignored.
       *
       * If an error argument is provided, then it will be emitted in an
       * 'error' event.
       */
      destroy(er) {
        if (this[DESTROYED]) {
          if (er)
            this.emit("error", er);
          else
            this.emit(DESTROYED);
          return this;
        }
        this[DESTROYED] = true;
        this[DISCARDED] = true;
        this[BUFFER].length = 0;
        this[BUFFERLENGTH] = 0;
        const wc = this;
        if (typeof wc.close === "function" && !this[CLOSED])
          wc.close();
        if (er)
          this.emit("error", er);
        else
          this.emit(DESTROYED);
        return this;
      }
      /**
       * Alias for {@link isStream}
       *
       * Former export location, maintained for backwards compatibility.
       *
       * @deprecated
       */
      static get isStream() {
        return exports2.isStream;
      }
    };
    exports2.Minipass = Minipass;
  }
});

// ../../../node_modules/@isaacs/fs-minipass/dist/commonjs/index.js
var require_commonjs2 = __commonJS({
  "../../../node_modules/@isaacs/fs-minipass/dist/commonjs/index.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.WriteStreamSync = exports2.WriteStream = exports2.ReadStreamSync = exports2.ReadStream = void 0;
    var events_1 = __importDefault(require("events"));
    var fs_1 = __importDefault(require("fs"));
    var minipass_1 = require_commonjs();
    var writev = fs_1.default.writev;
    var _autoClose = /* @__PURE__ */ Symbol("_autoClose");
    var _close = /* @__PURE__ */ Symbol("_close");
    var _ended = /* @__PURE__ */ Symbol("_ended");
    var _fd = /* @__PURE__ */ Symbol("_fd");
    var _finished = /* @__PURE__ */ Symbol("_finished");
    var _flags = /* @__PURE__ */ Symbol("_flags");
    var _flush = /* @__PURE__ */ Symbol("_flush");
    var _handleChunk = /* @__PURE__ */ Symbol("_handleChunk");
    var _makeBuf = /* @__PURE__ */ Symbol("_makeBuf");
    var _mode = /* @__PURE__ */ Symbol("_mode");
    var _needDrain = /* @__PURE__ */ Symbol("_needDrain");
    var _onerror = /* @__PURE__ */ Symbol("_onerror");
    var _onopen = /* @__PURE__ */ Symbol("_onopen");
    var _onread = /* @__PURE__ */ Symbol("_onread");
    var _onwrite = /* @__PURE__ */ Symbol("_onwrite");
    var _open = /* @__PURE__ */ Symbol("_open");
    var _path = /* @__PURE__ */ Symbol("_path");
    var _pos = /* @__PURE__ */ Symbol("_pos");
    var _queue = /* @__PURE__ */ Symbol("_queue");
    var _read = /* @__PURE__ */ Symbol("_read");
    var _readSize = /* @__PURE__ */ Symbol("_readSize");
    var _reading = /* @__PURE__ */ Symbol("_reading");
    var _remain = /* @__PURE__ */ Symbol("_remain");
    var _size = /* @__PURE__ */ Symbol("_size");
    var _write = /* @__PURE__ */ Symbol("_write");
    var _writing = /* @__PURE__ */ Symbol("_writing");
    var _defaultFlag = /* @__PURE__ */ Symbol("_defaultFlag");
    var _errored = /* @__PURE__ */ Symbol("_errored");
    var ReadStream = class extends minipass_1.Minipass {
      [_errored] = false;
      [_fd];
      [_path];
      [_readSize];
      [_reading] = false;
      [_size];
      [_remain];
      [_autoClose];
      constructor(path2, opt) {
        opt = opt || {};
        super(opt);
        this.readable = true;
        this.writable = false;
        if (typeof path2 !== "string") {
          throw new TypeError("path must be a string");
        }
        this[_errored] = false;
        this[_fd] = typeof opt.fd === "number" ? opt.fd : void 0;
        this[_path] = path2;
        this[_readSize] = opt.readSize || 16 * 1024 * 1024;
        this[_reading] = false;
        this[_size] = typeof opt.size === "number" ? opt.size : Infinity;
        this[_remain] = this[_size];
        this[_autoClose] = typeof opt.autoClose === "boolean" ? opt.autoClose : true;
        if (typeof this[_fd] === "number") {
          this[_read]();
        } else {
          this[_open]();
        }
      }
      get fd() {
        return this[_fd];
      }
      get path() {
        return this[_path];
      }
      //@ts-ignore
      write() {
        throw new TypeError("this is a readable stream");
      }
      //@ts-ignore
      end() {
        throw new TypeError("this is a readable stream");
      }
      [_open]() {
        fs_1.default.open(this[_path], "r", (er, fd) => this[_onopen](er, fd));
      }
      [_onopen](er, fd) {
        if (er) {
          this[_onerror](er);
        } else {
          this[_fd] = fd;
          this.emit("open", fd);
          this[_read]();
        }
      }
      [_makeBuf]() {
        return Buffer.allocUnsafe(Math.min(this[_readSize], this[_remain]));
      }
      [_read]() {
        if (!this[_reading]) {
          this[_reading] = true;
          const buf = this[_makeBuf]();
          if (buf.length === 0) {
            return process.nextTick(() => this[_onread](null, 0, buf));
          }
          fs_1.default.read(this[_fd], buf, 0, buf.length, null, (er, br, b) => this[_onread](er, br, b));
        }
      }
      [_onread](er, br, buf) {
        this[_reading] = false;
        if (er) {
          this[_onerror](er);
        } else if (this[_handleChunk](br, buf)) {
          this[_read]();
        }
      }
      [_close]() {
        if (this[_autoClose] && typeof this[_fd] === "number") {
          const fd = this[_fd];
          this[_fd] = void 0;
          fs_1.default.close(fd, (er) => er ? this.emit("error", er) : this.emit("close"));
        }
      }
      [_onerror](er) {
        this[_reading] = true;
        this[_close]();
        this.emit("error", er);
      }
      [_handleChunk](br, buf) {
        let ret = false;
        this[_remain] -= br;
        if (br > 0) {
          ret = super.write(br < buf.length ? buf.subarray(0, br) : buf);
        }
        if (br === 0 || this[_remain] <= 0) {
          ret = false;
          this[_close]();
          super.end();
        }
        return ret;
      }
      emit(ev, ...args) {
        switch (ev) {
          case "prefinish":
          case "finish":
            return false;
          case "drain":
            if (typeof this[_fd] === "number") {
              this[_read]();
            }
            return false;
          case "error":
            if (this[_errored]) {
              return false;
            }
            this[_errored] = true;
            return super.emit(ev, ...args);
          default:
            return super.emit(ev, ...args);
        }
      }
    };
    exports2.ReadStream = ReadStream;
    var ReadStreamSync = class extends ReadStream {
      [_open]() {
        let threw = true;
        try {
          this[_onopen](null, fs_1.default.openSync(this[_path], "r"));
          threw = false;
        } finally {
          if (threw) {
            this[_close]();
          }
        }
      }
      [_read]() {
        let threw = true;
        try {
          if (!this[_reading]) {
            this[_reading] = true;
            do {
              const buf = this[_makeBuf]();
              const br = buf.length === 0 ? 0 : fs_1.default.readSync(this[_fd], buf, 0, buf.length, null);
              if (!this[_handleChunk](br, buf)) {
                break;
              }
            } while (true);
            this[_reading] = false;
          }
          threw = false;
        } finally {
          if (threw) {
            this[_close]();
          }
        }
      }
      [_close]() {
        if (this[_autoClose] && typeof this[_fd] === "number") {
          const fd = this[_fd];
          this[_fd] = void 0;
          fs_1.default.closeSync(fd);
          this.emit("close");
        }
      }
    };
    exports2.ReadStreamSync = ReadStreamSync;
    var WriteStream = class extends events_1.default {
      readable = false;
      writable = true;
      [_errored] = false;
      [_writing] = false;
      [_ended] = false;
      [_queue] = [];
      [_needDrain] = false;
      [_path];
      [_mode];
      [_autoClose];
      [_fd];
      [_defaultFlag];
      [_flags];
      [_finished] = false;
      [_pos];
      constructor(path2, opt) {
        opt = opt || {};
        super(opt);
        this[_path] = path2;
        this[_fd] = typeof opt.fd === "number" ? opt.fd : void 0;
        this[_mode] = opt.mode === void 0 ? 438 : opt.mode;
        this[_pos] = typeof opt.start === "number" ? opt.start : void 0;
        this[_autoClose] = typeof opt.autoClose === "boolean" ? opt.autoClose : true;
        const defaultFlag = this[_pos] !== void 0 ? "r+" : "w";
        this[_defaultFlag] = opt.flags === void 0;
        this[_flags] = opt.flags === void 0 ? defaultFlag : opt.flags;
        if (this[_fd] === void 0) {
          this[_open]();
        }
      }
      emit(ev, ...args) {
        if (ev === "error") {
          if (this[_errored]) {
            return false;
          }
          this[_errored] = true;
        }
        return super.emit(ev, ...args);
      }
      get fd() {
        return this[_fd];
      }
      get path() {
        return this[_path];
      }
      [_onerror](er) {
        this[_close]();
        this[_writing] = true;
        this.emit("error", er);
      }
      [_open]() {
        fs_1.default.open(this[_path], this[_flags], this[_mode], (er, fd) => this[_onopen](er, fd));
      }
      [_onopen](er, fd) {
        if (this[_defaultFlag] && this[_flags] === "r+" && er && er.code === "ENOENT") {
          this[_flags] = "w";
          this[_open]();
        } else if (er) {
          this[_onerror](er);
        } else {
          this[_fd] = fd;
          this.emit("open", fd);
          if (!this[_writing]) {
            this[_flush]();
          }
        }
      }
      end(buf, enc) {
        if (buf) {
          this.write(buf, enc);
        }
        this[_ended] = true;
        if (!this[_writing] && !this[_queue].length && typeof this[_fd] === "number") {
          this[_onwrite](null, 0);
        }
        return this;
      }
      write(buf, enc) {
        if (typeof buf === "string") {
          buf = Buffer.from(buf, enc);
        }
        if (this[_ended]) {
          this.emit("error", new Error("write() after end()"));
          return false;
        }
        if (this[_fd] === void 0 || this[_writing] || this[_queue].length) {
          this[_queue].push(buf);
          this[_needDrain] = true;
          return false;
        }
        this[_writing] = true;
        this[_write](buf);
        return true;
      }
      [_write](buf) {
        fs_1.default.write(this[_fd], buf, 0, buf.length, this[_pos], (er, bw) => this[_onwrite](er, bw));
      }
      [_onwrite](er, bw) {
        if (er) {
          this[_onerror](er);
        } else {
          if (this[_pos] !== void 0 && typeof bw === "number") {
            this[_pos] += bw;
          }
          if (this[_queue].length) {
            this[_flush]();
          } else {
            this[_writing] = false;
            if (this[_ended] && !this[_finished]) {
              this[_finished] = true;
              this[_close]();
              this.emit("finish");
            } else if (this[_needDrain]) {
              this[_needDrain] = false;
              this.emit("drain");
            }
          }
        }
      }
      [_flush]() {
        if (this[_queue].length === 0) {
          if (this[_ended]) {
            this[_onwrite](null, 0);
          }
        } else if (this[_queue].length === 1) {
          this[_write](this[_queue].pop());
        } else {
          const iovec = this[_queue];
          this[_queue] = [];
          writev(this[_fd], iovec, this[_pos], (er, bw) => this[_onwrite](er, bw));
        }
      }
      [_close]() {
        if (this[_autoClose] && typeof this[_fd] === "number") {
          const fd = this[_fd];
          this[_fd] = void 0;
          fs_1.default.close(fd, (er) => er ? this.emit("error", er) : this.emit("close"));
        }
      }
    };
    exports2.WriteStream = WriteStream;
    var WriteStreamSync = class extends WriteStream {
      [_open]() {
        let fd;
        if (this[_defaultFlag] && this[_flags] === "r+") {
          try {
            fd = fs_1.default.openSync(this[_path], this[_flags], this[_mode]);
          } catch (er) {
            if (er?.code === "ENOENT") {
              this[_flags] = "w";
              return this[_open]();
            } else {
              throw er;
            }
          }
        } else {
          fd = fs_1.default.openSync(this[_path], this[_flags], this[_mode]);
        }
        this[_onopen](null, fd);
      }
      [_close]() {
        if (this[_autoClose] && typeof this[_fd] === "number") {
          const fd = this[_fd];
          this[_fd] = void 0;
          fs_1.default.closeSync(fd);
          this.emit("close");
        }
      }
      [_write](buf) {
        let threw = true;
        try {
          this[_onwrite](null, fs_1.default.writeSync(this[_fd], buf, 0, buf.length, this[_pos]));
          threw = false;
        } finally {
          if (threw) {
            try {
              this[_close]();
            } catch {
            }
          }
        }
      }
    };
    exports2.WriteStreamSync = WriteStreamSync;
  }
});

// ../node_modules/tar/dist/commonjs/options.js
var require_options = __commonJS({
  "../node_modules/tar/dist/commonjs/options.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.dealias = exports2.isNoFile = exports2.isFile = exports2.isAsync = exports2.isSync = exports2.isAsyncNoFile = exports2.isSyncNoFile = exports2.isAsyncFile = exports2.isSyncFile = void 0;
    var argmap = /* @__PURE__ */ new Map([
      ["C", "cwd"],
      ["f", "file"],
      ["z", "gzip"],
      ["P", "preservePaths"],
      ["U", "unlink"],
      ["strip-components", "strip"],
      ["stripComponents", "strip"],
      ["keep-newer", "newer"],
      ["keepNewer", "newer"],
      ["keep-newer-files", "newer"],
      ["keepNewerFiles", "newer"],
      ["k", "keep"],
      ["keep-existing", "keep"],
      ["keepExisting", "keep"],
      ["m", "noMtime"],
      ["no-mtime", "noMtime"],
      ["p", "preserveOwner"],
      ["L", "follow"],
      ["h", "follow"],
      ["onentry", "onReadEntry"]
    ]);
    var isSyncFile = (o) => !!o.sync && !!o.file;
    exports2.isSyncFile = isSyncFile;
    var isAsyncFile = (o) => !o.sync && !!o.file;
    exports2.isAsyncFile = isAsyncFile;
    var isSyncNoFile = (o) => !!o.sync && !o.file;
    exports2.isSyncNoFile = isSyncNoFile;
    var isAsyncNoFile = (o) => !o.sync && !o.file;
    exports2.isAsyncNoFile = isAsyncNoFile;
    var isSync = (o) => !!o.sync;
    exports2.isSync = isSync;
    var isAsync = (o) => !o.sync;
    exports2.isAsync = isAsync;
    var isFile = (o) => !!o.file;
    exports2.isFile = isFile;
    var isNoFile = (o) => !o.file;
    exports2.isNoFile = isNoFile;
    var dealiasKey = (k) => {
      const d = argmap.get(k);
      if (d)
        return d;
      return k;
    };
    var dealias = (opt = {}) => {
      if (!opt)
        return {};
      const result = {};
      for (const [key, v] of Object.entries(opt)) {
        const k = dealiasKey(key);
        result[k] = v;
      }
      if (result.chmod === void 0 && result.noChmod === false) {
        result.chmod = true;
      }
      delete result.noChmod;
      return result;
    };
    exports2.dealias = dealias;
  }
});

// ../node_modules/tar/dist/commonjs/make-command.js
var require_make_command = __commonJS({
  "../node_modules/tar/dist/commonjs/make-command.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.makeCommand = void 0;
    var options_js_1 = require_options();
    var makeCommand = (syncFile, asyncFile, syncNoFile, asyncNoFile, validate) => {
      return Object.assign((opt_ = [], entries, cb) => {
        if (Array.isArray(opt_)) {
          entries = opt_;
          opt_ = {};
        }
        if (typeof entries === "function") {
          cb = entries;
          entries = void 0;
        }
        entries = !entries ? [] : Array.from(entries);
        const opt = (0, options_js_1.dealias)(opt_);
        validate?.(opt, entries);
        if ((0, options_js_1.isSyncFile)(opt)) {
          if (typeof cb === "function") {
            throw new TypeError("callback not supported for sync tar functions");
          }
          return syncFile(opt, entries);
        } else if ((0, options_js_1.isAsyncFile)(opt)) {
          const p = asyncFile(opt, entries);
          return cb ? p.then(() => cb(), cb) : p;
        } else if ((0, options_js_1.isSyncNoFile)(opt)) {
          if (typeof cb === "function") {
            throw new TypeError("callback not supported for sync tar functions");
          }
          return syncNoFile(opt, entries);
        } else if ((0, options_js_1.isAsyncNoFile)(opt)) {
          if (typeof cb === "function") {
            throw new TypeError("callback only supported with file option");
          }
          return asyncNoFile(opt, entries);
        }
        throw new Error("impossible options??");
      }, {
        syncFile,
        asyncFile,
        syncNoFile,
        asyncNoFile,
        validate
      });
    };
    exports2.makeCommand = makeCommand;
  }
});

// ../node_modules/minipass/dist/commonjs/index.js
var require_commonjs3 = __commonJS({
  "../node_modules/minipass/dist/commonjs/index.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.Minipass = exports2.isWritable = exports2.isReadable = exports2.isStream = void 0;
    var proc = typeof process === "object" && process ? process : {
      stdout: null,
      stderr: null
    };
    var node_events_1 = require("node:events");
    var node_stream_1 = __importDefault(require("node:stream"));
    var node_string_decoder_1 = require("node:string_decoder");
    var isStream = (s) => !!s && typeof s === "object" && (s instanceof Minipass || s instanceof node_stream_1.default || (0, exports2.isReadable)(s) || (0, exports2.isWritable)(s));
    exports2.isStream = isStream;
    var isReadable = (s) => !!s && typeof s === "object" && s instanceof node_events_1.EventEmitter && typeof s.pipe === "function" && // node core Writable streams have a pipe() method, but it throws
    s.pipe !== node_stream_1.default.Writable.prototype.pipe;
    exports2.isReadable = isReadable;
    var isWritable = (s) => !!s && typeof s === "object" && s instanceof node_events_1.EventEmitter && typeof s.write === "function" && typeof s.end === "function";
    exports2.isWritable = isWritable;
    var EOF = /* @__PURE__ */ Symbol("EOF");
    var MAYBE_EMIT_END = /* @__PURE__ */ Symbol("maybeEmitEnd");
    var EMITTED_END = /* @__PURE__ */ Symbol("emittedEnd");
    var EMITTING_END = /* @__PURE__ */ Symbol("emittingEnd");
    var EMITTED_ERROR = /* @__PURE__ */ Symbol("emittedError");
    var CLOSED = /* @__PURE__ */ Symbol("closed");
    var READ = /* @__PURE__ */ Symbol("read");
    var FLUSH = /* @__PURE__ */ Symbol("flush");
    var FLUSHCHUNK = /* @__PURE__ */ Symbol("flushChunk");
    var ENCODING = /* @__PURE__ */ Symbol("encoding");
    var DECODER = /* @__PURE__ */ Symbol("decoder");
    var FLOWING = /* @__PURE__ */ Symbol("flowing");
    var PAUSED = /* @__PURE__ */ Symbol("paused");
    var RESUME = /* @__PURE__ */ Symbol("resume");
    var BUFFER = /* @__PURE__ */ Symbol("buffer");
    var PIPES = /* @__PURE__ */ Symbol("pipes");
    var BUFFERLENGTH = /* @__PURE__ */ Symbol("bufferLength");
    var BUFFERPUSH = /* @__PURE__ */ Symbol("bufferPush");
    var BUFFERSHIFT = /* @__PURE__ */ Symbol("bufferShift");
    var OBJECTMODE = /* @__PURE__ */ Symbol("objectMode");
    var DESTROYED = /* @__PURE__ */ Symbol("destroyed");
    var ERROR = /* @__PURE__ */ Symbol("error");
    var EMITDATA = /* @__PURE__ */ Symbol("emitData");
    var EMITEND = /* @__PURE__ */ Symbol("emitEnd");
    var EMITEND2 = /* @__PURE__ */ Symbol("emitEnd2");
    var ASYNC = /* @__PURE__ */ Symbol("async");
    var ABORT = /* @__PURE__ */ Symbol("abort");
    var ABORTED = /* @__PURE__ */ Symbol("aborted");
    var SIGNAL = /* @__PURE__ */ Symbol("signal");
    var DATALISTENERS = /* @__PURE__ */ Symbol("dataListeners");
    var DISCARDED = /* @__PURE__ */ Symbol("discarded");
    var defer = (fn) => Promise.resolve().then(fn);
    var nodefer = (fn) => fn();
    var isEndish = (ev) => ev === "end" || ev === "finish" || ev === "prefinish";
    var isArrayBufferLike = (b) => b instanceof ArrayBuffer || !!b && typeof b === "object" && b.constructor && b.constructor.name === "ArrayBuffer" && b.byteLength >= 0;
    var isArrayBufferView = (b) => !Buffer.isBuffer(b) && ArrayBuffer.isView(b);
    var Pipe = class {
      src;
      dest;
      opts;
      ondrain;
      constructor(src, dest, opts) {
        this.src = src;
        this.dest = dest;
        this.opts = opts;
        this.ondrain = () => src[RESUME]();
        this.dest.on("drain", this.ondrain);
      }
      unpipe() {
        this.dest.removeListener("drain", this.ondrain);
      }
      // only here for the prototype
      /* c8 ignore start */
      proxyErrors(_er) {
      }
      /* c8 ignore stop */
      end() {
        this.unpipe();
        if (this.opts.end)
          this.dest.end();
      }
    };
    var PipeProxyErrors = class extends Pipe {
      unpipe() {
        this.src.removeListener("error", this.proxyErrors);
        super.unpipe();
      }
      constructor(src, dest, opts) {
        super(src, dest, opts);
        this.proxyErrors = (er) => this.dest.emit("error", er);
        src.on("error", this.proxyErrors);
      }
    };
    var isObjectModeOptions = (o) => !!o.objectMode;
    var isEncodingOptions = (o) => !o.objectMode && !!o.encoding && o.encoding !== "buffer";
    var Minipass = class extends node_events_1.EventEmitter {
      [FLOWING] = false;
      [PAUSED] = false;
      [PIPES] = [];
      [BUFFER] = [];
      [OBJECTMODE];
      [ENCODING];
      [ASYNC];
      [DECODER];
      [EOF] = false;
      [EMITTED_END] = false;
      [EMITTING_END] = false;
      [CLOSED] = false;
      [EMITTED_ERROR] = null;
      [BUFFERLENGTH] = 0;
      [DESTROYED] = false;
      [SIGNAL];
      [ABORTED] = false;
      [DATALISTENERS] = 0;
      [DISCARDED] = false;
      /**
       * true if the stream can be written
       */
      writable = true;
      /**
       * true if the stream can be read
       */
      readable = true;
      /**
       * If `RType` is Buffer, then options do not need to be provided.
       * Otherwise, an options object must be provided to specify either
       * {@link Minipass.SharedOptions.objectMode} or
       * {@link Minipass.SharedOptions.encoding}, as appropriate.
       */
      constructor(...args) {
        const options = args[0] || {};
        super();
        if (options.objectMode && typeof options.encoding === "string") {
          throw new TypeError("Encoding and objectMode may not be used together");
        }
        if (isObjectModeOptions(options)) {
          this[OBJECTMODE] = true;
          this[ENCODING] = null;
        } else if (isEncodingOptions(options)) {
          this[ENCODING] = options.encoding;
          this[OBJECTMODE] = false;
        } else {
          this[OBJECTMODE] = false;
          this[ENCODING] = null;
        }
        this[ASYNC] = !!options.async;
        this[DECODER] = this[ENCODING] ? new node_string_decoder_1.StringDecoder(this[ENCODING]) : null;
        if (options && options.debugExposeBuffer === true) {
          Object.defineProperty(this, "buffer", { get: () => this[BUFFER] });
        }
        if (options && options.debugExposePipes === true) {
          Object.defineProperty(this, "pipes", { get: () => this[PIPES] });
        }
        const { signal } = options;
        if (signal) {
          this[SIGNAL] = signal;
          if (signal.aborted) {
            this[ABORT]();
          } else {
            signal.addEventListener("abort", () => this[ABORT]());
          }
        }
      }
      /**
       * The amount of data stored in the buffer waiting to be read.
       *
       * For Buffer strings, this will be the total byte length.
       * For string encoding streams, this will be the string character length,
       * according to JavaScript's `string.length` logic.
       * For objectMode streams, this is a count of the items waiting to be
       * emitted.
       */
      get bufferLength() {
        return this[BUFFERLENGTH];
      }
      /**
       * The `BufferEncoding` currently in use, or `null`
       */
      get encoding() {
        return this[ENCODING];
      }
      /**
       * @deprecated - This is a read only property
       */
      set encoding(_enc) {
        throw new Error("Encoding must be set at instantiation time");
      }
      /**
       * @deprecated - Encoding may only be set at instantiation time
       */
      setEncoding(_enc) {
        throw new Error("Encoding must be set at instantiation time");
      }
      /**
       * True if this is an objectMode stream
       */
      get objectMode() {
        return this[OBJECTMODE];
      }
      /**
       * @deprecated - This is a read-only property
       */
      set objectMode(_om) {
        throw new Error("objectMode must be set at instantiation time");
      }
      /**
       * true if this is an async stream
       */
      get ["async"]() {
        return this[ASYNC];
      }
      /**
       * Set to true to make this stream async.
       *
       * Once set, it cannot be unset, as this would potentially cause incorrect
       * behavior.  Ie, a sync stream can be made async, but an async stream
       * cannot be safely made sync.
       */
      set ["async"](a) {
        this[ASYNC] = this[ASYNC] || !!a;
      }
      // drop everything and get out of the flow completely
      [ABORT]() {
        this[ABORTED] = true;
        this.emit("abort", this[SIGNAL]?.reason);
        this.destroy(this[SIGNAL]?.reason);
      }
      /**
       * True if the stream has been aborted.
       */
      get aborted() {
        return this[ABORTED];
      }
      /**
       * No-op setter. Stream aborted status is set via the AbortSignal provided
       * in the constructor options.
       */
      set aborted(_) {
      }
      write(chunk, encoding, cb) {
        if (this[ABORTED])
          return false;
        if (this[EOF])
          throw new Error("write after end");
        if (this[DESTROYED]) {
          this.emit("error", Object.assign(new Error("Cannot call write after a stream was destroyed"), { code: "ERR_STREAM_DESTROYED" }));
          return true;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = "utf8";
        }
        if (!encoding)
          encoding = "utf8";
        const fn = this[ASYNC] ? defer : nodefer;
        if (!this[OBJECTMODE] && !Buffer.isBuffer(chunk)) {
          if (isArrayBufferView(chunk)) {
            chunk = Buffer.from(chunk.buffer, chunk.byteOffset, chunk.byteLength);
          } else if (isArrayBufferLike(chunk)) {
            chunk = Buffer.from(chunk);
          } else if (typeof chunk !== "string") {
            throw new Error("Non-contiguous data written to non-objectMode stream");
          }
        }
        if (this[OBJECTMODE]) {
          if (this[FLOWING] && this[BUFFERLENGTH] !== 0)
            this[FLUSH](true);
          if (this[FLOWING])
            this.emit("data", chunk);
          else
            this[BUFFERPUSH](chunk);
          if (this[BUFFERLENGTH] !== 0)
            this.emit("readable");
          if (cb)
            fn(cb);
          return this[FLOWING];
        }
        if (!chunk.length) {
          if (this[BUFFERLENGTH] !== 0)
            this.emit("readable");
          if (cb)
            fn(cb);
          return this[FLOWING];
        }
        if (typeof chunk === "string" && // unless it is a string already ready for us to use
        !(encoding === this[ENCODING] && !this[DECODER]?.lastNeed)) {
          chunk = Buffer.from(chunk, encoding);
        }
        if (Buffer.isBuffer(chunk) && this[ENCODING]) {
          chunk = this[DECODER].write(chunk);
        }
        if (this[FLOWING] && this[BUFFERLENGTH] !== 0)
          this[FLUSH](true);
        if (this[FLOWING])
          this.emit("data", chunk);
        else
          this[BUFFERPUSH](chunk);
        if (this[BUFFERLENGTH] !== 0)
          this.emit("readable");
        if (cb)
          fn(cb);
        return this[FLOWING];
      }
      /**
       * Low-level explicit read method.
       *
       * In objectMode, the argument is ignored, and one item is returned if
       * available.
       *
       * `n` is the number of bytes (or in the case of encoding streams,
       * characters) to consume. If `n` is not provided, then the entire buffer
       * is returned, or `null` is returned if no data is available.
       *
       * If `n` is greater that the amount of data in the internal buffer,
       * then `null` is returned.
       */
      read(n) {
        if (this[DESTROYED])
          return null;
        this[DISCARDED] = false;
        if (this[BUFFERLENGTH] === 0 || n === 0 || n && n > this[BUFFERLENGTH]) {
          this[MAYBE_EMIT_END]();
          return null;
        }
        if (this[OBJECTMODE])
          n = null;
        if (this[BUFFER].length > 1 && !this[OBJECTMODE]) {
          this[BUFFER] = [
            this[ENCODING] ? this[BUFFER].join("") : Buffer.concat(this[BUFFER], this[BUFFERLENGTH])
          ];
        }
        const ret = this[READ](n || null, this[BUFFER][0]);
        this[MAYBE_EMIT_END]();
        return ret;
      }
      [READ](n, chunk) {
        if (this[OBJECTMODE])
          this[BUFFERSHIFT]();
        else {
          const c = chunk;
          if (n === c.length || n === null)
            this[BUFFERSHIFT]();
          else if (typeof c === "string") {
            this[BUFFER][0] = c.slice(n);
            chunk = c.slice(0, n);
            this[BUFFERLENGTH] -= n;
          } else {
            this[BUFFER][0] = c.subarray(n);
            chunk = c.subarray(0, n);
            this[BUFFERLENGTH] -= n;
          }
        }
        this.emit("data", chunk);
        if (!this[BUFFER].length && !this[EOF])
          this.emit("drain");
        return chunk;
      }
      end(chunk, encoding, cb) {
        if (typeof chunk === "function") {
          cb = chunk;
          chunk = void 0;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = "utf8";
        }
        if (chunk !== void 0)
          this.write(chunk, encoding);
        if (cb)
          this.once("end", cb);
        this[EOF] = true;
        this.writable = false;
        if (this[FLOWING] || !this[PAUSED])
          this[MAYBE_EMIT_END]();
        return this;
      }
      // don't let the internal resume be overwritten
      [RESUME]() {
        if (this[DESTROYED])
          return;
        if (!this[DATALISTENERS] && !this[PIPES].length) {
          this[DISCARDED] = true;
        }
        this[PAUSED] = false;
        this[FLOWING] = true;
        this.emit("resume");
        if (this[BUFFER].length)
          this[FLUSH]();
        else if (this[EOF])
          this[MAYBE_EMIT_END]();
        else
          this.emit("drain");
      }
      /**
       * Resume the stream if it is currently in a paused state
       *
       * If called when there are no pipe destinations or `data` event listeners,
       * this will place the stream in a "discarded" state, where all data will
       * be thrown away. The discarded state is removed if a pipe destination or
       * data handler is added, if pause() is called, or if any synchronous or
       * asynchronous iteration is started.
       */
      resume() {
        return this[RESUME]();
      }
      /**
       * Pause the stream
       */
      pause() {
        this[FLOWING] = false;
        this[PAUSED] = true;
        this[DISCARDED] = false;
      }
      /**
       * true if the stream has been forcibly destroyed
       */
      get destroyed() {
        return this[DESTROYED];
      }
      /**
       * true if the stream is currently in a flowing state, meaning that
       * any writes will be immediately emitted.
       */
      get flowing() {
        return this[FLOWING];
      }
      /**
       * true if the stream is currently in a paused state
       */
      get paused() {
        return this[PAUSED];
      }
      [BUFFERPUSH](chunk) {
        if (this[OBJECTMODE])
          this[BUFFERLENGTH] += 1;
        else
          this[BUFFERLENGTH] += chunk.length;
        this[BUFFER].push(chunk);
      }
      [BUFFERSHIFT]() {
        if (this[OBJECTMODE])
          this[BUFFERLENGTH] -= 1;
        else
          this[BUFFERLENGTH] -= this[BUFFER][0].length;
        return this[BUFFER].shift();
      }
      [FLUSH](noDrain = false) {
        do {
        } while (this[FLUSHCHUNK](this[BUFFERSHIFT]()) && this[BUFFER].length);
        if (!noDrain && !this[BUFFER].length && !this[EOF])
          this.emit("drain");
      }
      [FLUSHCHUNK](chunk) {
        this.emit("data", chunk);
        return this[FLOWING];
      }
      /**
       * Pipe all data emitted by this stream into the destination provided.
       *
       * Triggers the flow of data.
       */
      pipe(dest, opts) {
        if (this[DESTROYED])
          return dest;
        this[DISCARDED] = false;
        const ended = this[EMITTED_END];
        opts = opts || {};
        if (dest === proc.stdout || dest === proc.stderr)
          opts.end = false;
        else
          opts.end = opts.end !== false;
        opts.proxyErrors = !!opts.proxyErrors;
        if (ended) {
          if (opts.end)
            dest.end();
        } else {
          this[PIPES].push(!opts.proxyErrors ? new Pipe(this, dest, opts) : new PipeProxyErrors(this, dest, opts));
          if (this[ASYNC])
            defer(() => this[RESUME]());
          else
            this[RESUME]();
        }
        return dest;
      }
      /**
       * Fully unhook a piped destination stream.
       *
       * If the destination stream was the only consumer of this stream (ie,
       * there are no other piped destinations or `'data'` event listeners)
       * then the flow of data will stop until there is another consumer or
       * {@link Minipass#resume} is explicitly called.
       */
      unpipe(dest) {
        const p = this[PIPES].find((p2) => p2.dest === dest);
        if (p) {
          if (this[PIPES].length === 1) {
            if (this[FLOWING] && this[DATALISTENERS] === 0) {
              this[FLOWING] = false;
            }
            this[PIPES] = [];
          } else
            this[PIPES].splice(this[PIPES].indexOf(p), 1);
          p.unpipe();
        }
      }
      /**
       * Alias for {@link Minipass#on}
       */
      addListener(ev, handler) {
        return this.on(ev, handler);
      }
      /**
       * Mostly identical to `EventEmitter.on`, with the following
       * behavior differences to prevent data loss and unnecessary hangs:
       *
       * - Adding a 'data' event handler will trigger the flow of data
       *
       * - Adding a 'readable' event handler when there is data waiting to be read
       *   will cause 'readable' to be emitted immediately.
       *
       * - Adding an 'endish' event handler ('end', 'finish', etc.) which has
       *   already passed will cause the event to be emitted immediately and all
       *   handlers removed.
       *
       * - Adding an 'error' event handler after an error has been emitted will
       *   cause the event to be re-emitted immediately with the error previously
       *   raised.
       */
      on(ev, handler) {
        const ret = super.on(ev, handler);
        if (ev === "data") {
          this[DISCARDED] = false;
          this[DATALISTENERS]++;
          if (!this[PIPES].length && !this[FLOWING]) {
            this[RESUME]();
          }
        } else if (ev === "readable" && this[BUFFERLENGTH] !== 0) {
          super.emit("readable");
        } else if (isEndish(ev) && this[EMITTED_END]) {
          super.emit(ev);
          this.removeAllListeners(ev);
        } else if (ev === "error" && this[EMITTED_ERROR]) {
          const h = handler;
          if (this[ASYNC])
            defer(() => h.call(this, this[EMITTED_ERROR]));
          else
            h.call(this, this[EMITTED_ERROR]);
        }
        return ret;
      }
      /**
       * Alias for {@link Minipass#off}
       */
      removeListener(ev, handler) {
        return this.off(ev, handler);
      }
      /**
       * Mostly identical to `EventEmitter.off`
       *
       * If a 'data' event handler is removed, and it was the last consumer
       * (ie, there are no pipe destinations or other 'data' event listeners),
       * then the flow of data will stop until there is another consumer or
       * {@link Minipass#resume} is explicitly called.
       */
      off(ev, handler) {
        const ret = super.off(ev, handler);
        if (ev === "data") {
          this[DATALISTENERS] = this.listeners("data").length;
          if (this[DATALISTENERS] === 0 && !this[DISCARDED] && !this[PIPES].length) {
            this[FLOWING] = false;
          }
        }
        return ret;
      }
      /**
       * Mostly identical to `EventEmitter.removeAllListeners`
       *
       * If all 'data' event handlers are removed, and they were the last consumer
       * (ie, there are no pipe destinations), then the flow of data will stop
       * until there is another consumer or {@link Minipass#resume} is explicitly
       * called.
       */
      removeAllListeners(ev) {
        const ret = super.removeAllListeners(ev);
        if (ev === "data" || ev === void 0) {
          this[DATALISTENERS] = 0;
          if (!this[DISCARDED] && !this[PIPES].length) {
            this[FLOWING] = false;
          }
        }
        return ret;
      }
      /**
       * true if the 'end' event has been emitted
       */
      get emittedEnd() {
        return this[EMITTED_END];
      }
      [MAYBE_EMIT_END]() {
        if (!this[EMITTING_END] && !this[EMITTED_END] && !this[DESTROYED] && this[BUFFER].length === 0 && this[EOF]) {
          this[EMITTING_END] = true;
          this.emit("end");
          this.emit("prefinish");
          this.emit("finish");
          if (this[CLOSED])
            this.emit("close");
          this[EMITTING_END] = false;
        }
      }
      /**
       * Mostly identical to `EventEmitter.emit`, with the following
       * behavior differences to prevent data loss and unnecessary hangs:
       *
       * If the stream has been destroyed, and the event is something other
       * than 'close' or 'error', then `false` is returned and no handlers
       * are called.
       *
       * If the event is 'end', and has already been emitted, then the event
       * is ignored. If the stream is in a paused or non-flowing state, then
       * the event will be deferred until data flow resumes. If the stream is
       * async, then handlers will be called on the next tick rather than
       * immediately.
       *
       * If the event is 'close', and 'end' has not yet been emitted, then
       * the event will be deferred until after 'end' is emitted.
       *
       * If the event is 'error', and an AbortSignal was provided for the stream,
       * and there are no listeners, then the event is ignored, matching the
       * behavior of node core streams in the presense of an AbortSignal.
       *
       * If the event is 'finish' or 'prefinish', then all listeners will be
       * removed after emitting the event, to prevent double-firing.
       */
      emit(ev, ...args) {
        const data = args[0];
        if (ev !== "error" && ev !== "close" && ev !== DESTROYED && this[DESTROYED]) {
          return false;
        } else if (ev === "data") {
          return !this[OBJECTMODE] && !data ? false : this[ASYNC] ? (defer(() => this[EMITDATA](data)), true) : this[EMITDATA](data);
        } else if (ev === "end") {
          return this[EMITEND]();
        } else if (ev === "close") {
          this[CLOSED] = true;
          if (!this[EMITTED_END] && !this[DESTROYED])
            return false;
          const ret2 = super.emit("close");
          this.removeAllListeners("close");
          return ret2;
        } else if (ev === "error") {
          this[EMITTED_ERROR] = data;
          super.emit(ERROR, data);
          const ret2 = !this[SIGNAL] || this.listeners("error").length ? super.emit("error", data) : false;
          this[MAYBE_EMIT_END]();
          return ret2;
        } else if (ev === "resume") {
          const ret2 = super.emit("resume");
          this[MAYBE_EMIT_END]();
          return ret2;
        } else if (ev === "finish" || ev === "prefinish") {
          const ret2 = super.emit(ev);
          this.removeAllListeners(ev);
          return ret2;
        }
        const ret = super.emit(ev, ...args);
        this[MAYBE_EMIT_END]();
        return ret;
      }
      [EMITDATA](data) {
        for (const p of this[PIPES]) {
          if (p.dest.write(data) === false)
            this.pause();
        }
        const ret = this[DISCARDED] ? false : super.emit("data", data);
        this[MAYBE_EMIT_END]();
        return ret;
      }
      [EMITEND]() {
        if (this[EMITTED_END])
          return false;
        this[EMITTED_END] = true;
        this.readable = false;
        return this[ASYNC] ? (defer(() => this[EMITEND2]()), true) : this[EMITEND2]();
      }
      [EMITEND2]() {
        if (this[DECODER]) {
          const data = this[DECODER].end();
          if (data) {
            for (const p of this[PIPES]) {
              p.dest.write(data);
            }
            if (!this[DISCARDED])
              super.emit("data", data);
          }
        }
        for (const p of this[PIPES]) {
          p.end();
        }
        const ret = super.emit("end");
        this.removeAllListeners("end");
        return ret;
      }
      /**
       * Return a Promise that resolves to an array of all emitted data once
       * the stream ends.
       */
      async collect() {
        const buf = Object.assign([], {
          dataLength: 0
        });
        if (!this[OBJECTMODE])
          buf.dataLength = 0;
        const p = this.promise();
        this.on("data", (c) => {
          buf.push(c);
          if (!this[OBJECTMODE])
            buf.dataLength += c.length;
        });
        await p;
        return buf;
      }
      /**
       * Return a Promise that resolves to the concatenation of all emitted data
       * once the stream ends.
       *
       * Not allowed on objectMode streams.
       */
      async concat() {
        if (this[OBJECTMODE]) {
          throw new Error("cannot concat in objectMode");
        }
        const buf = await this.collect();
        return this[ENCODING] ? buf.join("") : Buffer.concat(buf, buf.dataLength);
      }
      /**
       * Return a void Promise that resolves once the stream ends.
       */
      async promise() {
        return new Promise((resolve, reject) => {
          this.on(DESTROYED, () => reject(new Error("stream destroyed")));
          this.on("error", (er) => reject(er));
          this.on("end", () => resolve());
        });
      }
      /**
       * Asynchronous `for await of` iteration.
       *
       * This will continue emitting all chunks until the stream terminates.
       */
      [Symbol.asyncIterator]() {
        this[DISCARDED] = false;
        let stopped = false;
        const stop = async () => {
          this.pause();
          stopped = true;
          return { value: void 0, done: true };
        };
        const next = () => {
          if (stopped)
            return stop();
          const res = this.read();
          if (res !== null)
            return Promise.resolve({ done: false, value: res });
          if (this[EOF])
            return stop();
          let resolve;
          let reject;
          const onerr = (er) => {
            this.off("data", ondata);
            this.off("end", onend);
            this.off(DESTROYED, ondestroy);
            stop();
            reject(er);
          };
          const ondata = (value) => {
            this.off("error", onerr);
            this.off("end", onend);
            this.off(DESTROYED, ondestroy);
            this.pause();
            resolve({ value, done: !!this[EOF] });
          };
          const onend = () => {
            this.off("error", onerr);
            this.off("data", ondata);
            this.off(DESTROYED, ondestroy);
            stop();
            resolve({ done: true, value: void 0 });
          };
          const ondestroy = () => onerr(new Error("stream destroyed"));
          return new Promise((res2, rej) => {
            reject = rej;
            resolve = res2;
            this.once(DESTROYED, ondestroy);
            this.once("error", onerr);
            this.once("end", onend);
            this.once("data", ondata);
          });
        };
        return {
          next,
          throw: stop,
          return: stop,
          [Symbol.asyncIterator]() {
            return this;
          },
          [Symbol.asyncDispose]: async () => {
          }
        };
      }
      /**
       * Synchronous `for of` iteration.
       *
       * The iteration will terminate when the internal buffer runs out, even
       * if the stream has not yet terminated.
       */
      [Symbol.iterator]() {
        this[DISCARDED] = false;
        let stopped = false;
        const stop = () => {
          this.pause();
          this.off(ERROR, stop);
          this.off(DESTROYED, stop);
          this.off("end", stop);
          stopped = true;
          return { done: true, value: void 0 };
        };
        const next = () => {
          if (stopped)
            return stop();
          const value = this.read();
          return value === null ? stop() : { done: false, value };
        };
        this.once("end", stop);
        this.once(ERROR, stop);
        this.once(DESTROYED, stop);
        return {
          next,
          throw: stop,
          return: stop,
          [Symbol.iterator]() {
            return this;
          },
          [Symbol.dispose]: () => {
          }
        };
      }
      /**
       * Destroy a stream, preventing it from being used for any further purpose.
       *
       * If the stream has a `close()` method, then it will be called on
       * destruction.
       *
       * After destruction, any attempt to write data, read data, or emit most
       * events will be ignored.
       *
       * If an error argument is provided, then it will be emitted in an
       * 'error' event.
       */
      destroy(er) {
        if (this[DESTROYED]) {
          if (er)
            this.emit("error", er);
          else
            this.emit(DESTROYED);
          return this;
        }
        this[DESTROYED] = true;
        this[DISCARDED] = true;
        this[BUFFER].length = 0;
        this[BUFFERLENGTH] = 0;
        const wc = this;
        if (typeof wc.close === "function" && !this[CLOSED])
          wc.close();
        if (er)
          this.emit("error", er);
        else
          this.emit(DESTROYED);
        return this;
      }
      /**
       * Alias for {@link isStream}
       *
       * Former export location, maintained for backwards compatibility.
       *
       * @deprecated
       */
      static get isStream() {
        return exports2.isStream;
      }
    };
    exports2.Minipass = Minipass;
  }
});

// ../node_modules/minizlib/dist/commonjs/constants.js
var require_constants = __commonJS({
  "../node_modules/minizlib/dist/commonjs/constants.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.constants = void 0;
    var zlib_1 = __importDefault(require("zlib"));
    var realZlibConstants = zlib_1.default.constants || { ZLIB_VERNUM: 4736 };
    exports2.constants = Object.freeze(Object.assign(/* @__PURE__ */ Object.create(null), {
      Z_NO_FLUSH: 0,
      Z_PARTIAL_FLUSH: 1,
      Z_SYNC_FLUSH: 2,
      Z_FULL_FLUSH: 3,
      Z_FINISH: 4,
      Z_BLOCK: 5,
      Z_OK: 0,
      Z_STREAM_END: 1,
      Z_NEED_DICT: 2,
      Z_ERRNO: -1,
      Z_STREAM_ERROR: -2,
      Z_DATA_ERROR: -3,
      Z_MEM_ERROR: -4,
      Z_BUF_ERROR: -5,
      Z_VERSION_ERROR: -6,
      Z_NO_COMPRESSION: 0,
      Z_BEST_SPEED: 1,
      Z_BEST_COMPRESSION: 9,
      Z_DEFAULT_COMPRESSION: -1,
      Z_FILTERED: 1,
      Z_HUFFMAN_ONLY: 2,
      Z_RLE: 3,
      Z_FIXED: 4,
      Z_DEFAULT_STRATEGY: 0,
      DEFLATE: 1,
      INFLATE: 2,
      GZIP: 3,
      GUNZIP: 4,
      DEFLATERAW: 5,
      INFLATERAW: 6,
      UNZIP: 7,
      BROTLI_DECODE: 8,
      BROTLI_ENCODE: 9,
      Z_MIN_WINDOWBITS: 8,
      Z_MAX_WINDOWBITS: 15,
      Z_DEFAULT_WINDOWBITS: 15,
      Z_MIN_CHUNK: 64,
      Z_MAX_CHUNK: Infinity,
      Z_DEFAULT_CHUNK: 16384,
      Z_MIN_MEMLEVEL: 1,
      Z_MAX_MEMLEVEL: 9,
      Z_DEFAULT_MEMLEVEL: 8,
      Z_MIN_LEVEL: -1,
      Z_MAX_LEVEL: 9,
      Z_DEFAULT_LEVEL: -1,
      BROTLI_OPERATION_PROCESS: 0,
      BROTLI_OPERATION_FLUSH: 1,
      BROTLI_OPERATION_FINISH: 2,
      BROTLI_OPERATION_EMIT_METADATA: 3,
      BROTLI_MODE_GENERIC: 0,
      BROTLI_MODE_TEXT: 1,
      BROTLI_MODE_FONT: 2,
      BROTLI_DEFAULT_MODE: 0,
      BROTLI_MIN_QUALITY: 0,
      BROTLI_MAX_QUALITY: 11,
      BROTLI_DEFAULT_QUALITY: 11,
      BROTLI_MIN_WINDOW_BITS: 10,
      BROTLI_MAX_WINDOW_BITS: 24,
      BROTLI_LARGE_MAX_WINDOW_BITS: 30,
      BROTLI_DEFAULT_WINDOW: 22,
      BROTLI_MIN_INPUT_BLOCK_BITS: 16,
      BROTLI_MAX_INPUT_BLOCK_BITS: 24,
      BROTLI_PARAM_MODE: 0,
      BROTLI_PARAM_QUALITY: 1,
      BROTLI_PARAM_LGWIN: 2,
      BROTLI_PARAM_LGBLOCK: 3,
      BROTLI_PARAM_DISABLE_LITERAL_CONTEXT_MODELING: 4,
      BROTLI_PARAM_SIZE_HINT: 5,
      BROTLI_PARAM_LARGE_WINDOW: 6,
      BROTLI_PARAM_NPOSTFIX: 7,
      BROTLI_PARAM_NDIRECT: 8,
      BROTLI_DECODER_RESULT_ERROR: 0,
      BROTLI_DECODER_RESULT_SUCCESS: 1,
      BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT: 2,
      BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT: 3,
      BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION: 0,
      BROTLI_DECODER_PARAM_LARGE_WINDOW: 1,
      BROTLI_DECODER_NO_ERROR: 0,
      BROTLI_DECODER_SUCCESS: 1,
      BROTLI_DECODER_NEEDS_MORE_INPUT: 2,
      BROTLI_DECODER_NEEDS_MORE_OUTPUT: 3,
      BROTLI_DECODER_ERROR_FORMAT_EXUBERANT_NIBBLE: -1,
      BROTLI_DECODER_ERROR_FORMAT_RESERVED: -2,
      BROTLI_DECODER_ERROR_FORMAT_EXUBERANT_META_NIBBLE: -3,
      BROTLI_DECODER_ERROR_FORMAT_SIMPLE_HUFFMAN_ALPHABET: -4,
      BROTLI_DECODER_ERROR_FORMAT_SIMPLE_HUFFMAN_SAME: -5,
      BROTLI_DECODER_ERROR_FORMAT_CL_SPACE: -6,
      BROTLI_DECODER_ERROR_FORMAT_HUFFMAN_SPACE: -7,
      BROTLI_DECODER_ERROR_FORMAT_CONTEXT_MAP_REPEAT: -8,
      BROTLI_DECODER_ERROR_FORMAT_BLOCK_LENGTH_1: -9,
      BROTLI_DECODER_ERROR_FORMAT_BLOCK_LENGTH_2: -10,
      BROTLI_DECODER_ERROR_FORMAT_TRANSFORM: -11,
      BROTLI_DECODER_ERROR_FORMAT_DICTIONARY: -12,
      BROTLI_DECODER_ERROR_FORMAT_WINDOW_BITS: -13,
      BROTLI_DECODER_ERROR_FORMAT_PADDING_1: -14,
      BROTLI_DECODER_ERROR_FORMAT_PADDING_2: -15,
      BROTLI_DECODER_ERROR_FORMAT_DISTANCE: -16,
      BROTLI_DECODER_ERROR_DICTIONARY_NOT_SET: -19,
      BROTLI_DECODER_ERROR_INVALID_ARGUMENTS: -20,
      BROTLI_DECODER_ERROR_ALLOC_CONTEXT_MODES: -21,
      BROTLI_DECODER_ERROR_ALLOC_TREE_GROUPS: -22,
      BROTLI_DECODER_ERROR_ALLOC_CONTEXT_MAP: -25,
      BROTLI_DECODER_ERROR_ALLOC_RING_BUFFER_1: -26,
      BROTLI_DECODER_ERROR_ALLOC_RING_BUFFER_2: -27,
      BROTLI_DECODER_ERROR_ALLOC_BLOCK_TYPE_TREES: -30,
      BROTLI_DECODER_ERROR_UNREACHABLE: -31
    }, realZlibConstants));
  }
});

// ../node_modules/minizlib/dist/commonjs/index.js
var require_commonjs4 = __commonJS({
  "../node_modules/minizlib/dist/commonjs/index.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc2 = Object.getOwnPropertyDescriptor(m, k);
      if (!desc2 || ("get" in desc2 ? !m.__esModule : desc2.writable || desc2.configurable)) {
        desc2 = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc2);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.ZstdDecompress = exports2.ZstdCompress = exports2.BrotliDecompress = exports2.BrotliCompress = exports2.Unzip = exports2.InflateRaw = exports2.DeflateRaw = exports2.Gunzip = exports2.Gzip = exports2.Inflate = exports2.Deflate = exports2.Zlib = exports2.ZlibError = exports2.constants = void 0;
    var assert_1 = __importDefault(require("assert"));
    var buffer_1 = require("buffer");
    var minipass_1 = require_commonjs3();
    var realZlib = __importStar(require("zlib"));
    var constants_js_1 = require_constants();
    var constants_js_2 = require_constants();
    Object.defineProperty(exports2, "constants", { enumerable: true, get: function() {
      return constants_js_2.constants;
    } });
    var OriginalBufferConcat = buffer_1.Buffer.concat;
    var desc = Object.getOwnPropertyDescriptor(buffer_1.Buffer, "concat");
    var noop = (args) => args;
    var passthroughBufferConcat = desc?.writable === true || desc?.set !== void 0 ? (makeNoOp) => {
      buffer_1.Buffer.concat = makeNoOp ? noop : OriginalBufferConcat;
    } : (_) => {
    };
    var _superWrite = /* @__PURE__ */ Symbol("_superWrite");
    var ZlibError = class extends Error {
      code;
      errno;
      constructor(err, origin) {
        super("zlib: " + err.message, { cause: err });
        this.code = err.code;
        this.errno = err.errno;
        if (!this.code)
          this.code = "ZLIB_ERROR";
        this.message = "zlib: " + err.message;
        Error.captureStackTrace(this, origin ?? this.constructor);
      }
      get name() {
        return "ZlibError";
      }
    };
    exports2.ZlibError = ZlibError;
    var _flushFlag = /* @__PURE__ */ Symbol("flushFlag");
    var ZlibBase = class extends minipass_1.Minipass {
      #sawError = false;
      #ended = false;
      #flushFlag;
      #finishFlushFlag;
      #fullFlushFlag;
      #handle;
      #onError;
      get sawError() {
        return this.#sawError;
      }
      get handle() {
        return this.#handle;
      }
      /* c8 ignore start */
      get flushFlag() {
        return this.#flushFlag;
      }
      /* c8 ignore stop */
      constructor(opts, mode) {
        if (!opts || typeof opts !== "object")
          throw new TypeError("invalid options for ZlibBase constructor");
        super(opts);
        this.#flushFlag = opts.flush ?? 0;
        this.#finishFlushFlag = opts.finishFlush ?? 0;
        this.#fullFlushFlag = opts.fullFlushFlag ?? 0;
        if (typeof realZlib[mode] !== "function") {
          throw new TypeError("Compression method not supported: " + mode);
        }
        try {
          this.#handle = new realZlib[mode](opts);
        } catch (er) {
          throw new ZlibError(er, this.constructor);
        }
        this.#onError = (err) => {
          if (this.#sawError)
            return;
          this.#sawError = true;
          this.close();
          this.emit("error", err);
        };
        this.#handle?.on("error", (er) => this.#onError(new ZlibError(er)));
        this.once("end", () => this.close);
      }
      close() {
        if (this.#handle) {
          this.#handle.close();
          this.#handle = void 0;
          this.emit("close");
        }
      }
      reset() {
        if (!this.#sawError) {
          (0, assert_1.default)(this.#handle, "zlib binding closed");
          return this.#handle.reset?.();
        }
      }
      flush(flushFlag) {
        if (this.ended)
          return;
        if (typeof flushFlag !== "number")
          flushFlag = this.#fullFlushFlag;
        this.write(Object.assign(buffer_1.Buffer.alloc(0), { [_flushFlag]: flushFlag }));
      }
      end(chunk, encoding, cb) {
        if (typeof chunk === "function") {
          cb = chunk;
          encoding = void 0;
          chunk = void 0;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (chunk) {
          if (encoding)
            this.write(chunk, encoding);
          else
            this.write(chunk);
        }
        this.flush(this.#finishFlushFlag);
        this.#ended = true;
        return super.end(cb);
      }
      get ended() {
        return this.#ended;
      }
      // overridden in the gzip classes to do portable writes
      [_superWrite](data) {
        return super.write(data);
      }
      write(chunk, encoding, cb) {
        if (typeof encoding === "function")
          cb = encoding, encoding = "utf8";
        if (typeof chunk === "string")
          chunk = buffer_1.Buffer.from(chunk, encoding);
        if (this.#sawError)
          return;
        (0, assert_1.default)(this.#handle, "zlib binding closed");
        const nativeHandle = this.#handle._handle;
        const originalNativeClose = nativeHandle.close;
        nativeHandle.close = () => {
        };
        const originalClose = this.#handle.close;
        this.#handle.close = () => {
        };
        passthroughBufferConcat(true);
        let result = void 0;
        try {
          const flushFlag = typeof chunk[_flushFlag] === "number" ? chunk[_flushFlag] : this.#flushFlag;
          result = this.#handle._processChunk(chunk, flushFlag);
          passthroughBufferConcat(false);
        } catch (err) {
          passthroughBufferConcat(false);
          this.#onError(new ZlibError(err, this.write));
        } finally {
          if (this.#handle) {
            ;
            this.#handle._handle = nativeHandle;
            nativeHandle.close = originalNativeClose;
            this.#handle.close = originalClose;
            this.#handle.removeAllListeners("error");
          }
        }
        if (this.#handle)
          this.#handle.on("error", (er) => this.#onError(new ZlibError(er, this.write)));
        let writeReturn;
        if (result) {
          if (Array.isArray(result) && result.length > 0) {
            const r = result[0];
            writeReturn = this[_superWrite](buffer_1.Buffer.from(r));
            for (let i = 1; i < result.length; i++) {
              writeReturn = this[_superWrite](result[i]);
            }
          } else {
            writeReturn = this[_superWrite](buffer_1.Buffer.from(result));
          }
        }
        if (cb)
          cb();
        return writeReturn;
      }
    };
    var Zlib = class extends ZlibBase {
      #level;
      #strategy;
      constructor(opts, mode) {
        opts = opts || {};
        opts.flush = opts.flush || constants_js_1.constants.Z_NO_FLUSH;
        opts.finishFlush = opts.finishFlush || constants_js_1.constants.Z_FINISH;
        opts.fullFlushFlag = constants_js_1.constants.Z_FULL_FLUSH;
        super(opts, mode);
        this.#level = opts.level;
        this.#strategy = opts.strategy;
      }
      params(level, strategy) {
        if (this.sawError)
          return;
        if (!this.handle)
          throw new Error("cannot switch params when binding is closed");
        if (!this.handle.params)
          throw new Error("not supported in this implementation");
        if (this.#level !== level || this.#strategy !== strategy) {
          this.flush(constants_js_1.constants.Z_SYNC_FLUSH);
          (0, assert_1.default)(this.handle, "zlib binding closed");
          const origFlush = this.handle.flush;
          this.handle.flush = (flushFlag, cb) => {
            if (typeof flushFlag === "function") {
              cb = flushFlag;
              flushFlag = this.flushFlag;
            }
            this.flush(flushFlag);
            cb?.();
          };
          try {
            ;
            this.handle.params(level, strategy);
          } finally {
            this.handle.flush = origFlush;
          }
          if (this.handle) {
            this.#level = level;
            this.#strategy = strategy;
          }
        }
      }
    };
    exports2.Zlib = Zlib;
    var Deflate = class extends Zlib {
      constructor(opts) {
        super(opts, "Deflate");
      }
    };
    exports2.Deflate = Deflate;
    var Inflate = class extends Zlib {
      constructor(opts) {
        super(opts, "Inflate");
      }
    };
    exports2.Inflate = Inflate;
    var Gzip = class extends Zlib {
      #portable;
      constructor(opts) {
        super(opts, "Gzip");
        this.#portable = opts && !!opts.portable;
      }
      [_superWrite](data) {
        if (!this.#portable)
          return super[_superWrite](data);
        this.#portable = false;
        data[9] = 255;
        return super[_superWrite](data);
      }
    };
    exports2.Gzip = Gzip;
    var Gunzip = class extends Zlib {
      constructor(opts) {
        super(opts, "Gunzip");
      }
    };
    exports2.Gunzip = Gunzip;
    var DeflateRaw = class extends Zlib {
      constructor(opts) {
        super(opts, "DeflateRaw");
      }
    };
    exports2.DeflateRaw = DeflateRaw;
    var InflateRaw = class extends Zlib {
      constructor(opts) {
        super(opts, "InflateRaw");
      }
    };
    exports2.InflateRaw = InflateRaw;
    var Unzip = class extends Zlib {
      constructor(opts) {
        super(opts, "Unzip");
      }
    };
    exports2.Unzip = Unzip;
    var Brotli = class extends ZlibBase {
      constructor(opts, mode) {
        opts = opts || {};
        opts.flush = opts.flush || constants_js_1.constants.BROTLI_OPERATION_PROCESS;
        opts.finishFlush = opts.finishFlush || constants_js_1.constants.BROTLI_OPERATION_FINISH;
        opts.fullFlushFlag = constants_js_1.constants.BROTLI_OPERATION_FLUSH;
        super(opts, mode);
      }
    };
    var BrotliCompress = class extends Brotli {
      constructor(opts) {
        super(opts, "BrotliCompress");
      }
    };
    exports2.BrotliCompress = BrotliCompress;
    var BrotliDecompress = class extends Brotli {
      constructor(opts) {
        super(opts, "BrotliDecompress");
      }
    };
    exports2.BrotliDecompress = BrotliDecompress;
    var Zstd = class extends ZlibBase {
      constructor(opts, mode) {
        opts = opts || {};
        opts.flush = opts.flush || constants_js_1.constants.ZSTD_e_continue;
        opts.finishFlush = opts.finishFlush || constants_js_1.constants.ZSTD_e_end;
        opts.fullFlushFlag = constants_js_1.constants.ZSTD_e_flush;
        super(opts, mode);
      }
    };
    var ZstdCompress = class extends Zstd {
      constructor(opts) {
        super(opts, "ZstdCompress");
      }
    };
    exports2.ZstdCompress = ZstdCompress;
    var ZstdDecompress = class extends Zstd {
      constructor(opts) {
        super(opts, "ZstdDecompress");
      }
    };
    exports2.ZstdDecompress = ZstdDecompress;
  }
});

// ../node_modules/tar/dist/commonjs/large-numbers.js
var require_large_numbers = __commonJS({
  "../node_modules/tar/dist/commonjs/large-numbers.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.parse = exports2.encode = void 0;
    var encode = (num, buf) => {
      if (!Number.isSafeInteger(num)) {
        throw Error("cannot encode number outside of javascript safe integer range");
      } else if (num < 0) {
        encodeNegative(num, buf);
      } else {
        encodePositive(num, buf);
      }
      return buf;
    };
    exports2.encode = encode;
    var encodePositive = (num, buf) => {
      buf[0] = 128;
      for (var i = buf.length; i > 1; i--) {
        buf[i - 1] = num & 255;
        num = Math.floor(num / 256);
      }
    };
    var encodeNegative = (num, buf) => {
      buf[0] = 255;
      var flipped = false;
      num = num * -1;
      for (var i = buf.length; i > 1; i--) {
        var byte = num & 255;
        num = Math.floor(num / 256);
        if (flipped) {
          buf[i - 1] = onesComp(byte);
        } else if (byte === 0) {
          buf[i - 1] = 0;
        } else {
          flipped = true;
          buf[i - 1] = twosComp(byte);
        }
      }
    };
    var parse = (buf) => {
      const pre = buf[0];
      const value = pre === 128 ? pos(buf.subarray(1, buf.length)) : pre === 255 ? twos(buf) : null;
      if (value === null) {
        throw Error("invalid base256 encoding");
      }
      if (!Number.isSafeInteger(value)) {
        throw Error("parsed number outside of javascript safe integer range");
      }
      return value;
    };
    exports2.parse = parse;
    var twos = (buf) => {
      var len = buf.length;
      var sum = 0;
      var flipped = false;
      for (var i = len - 1; i > -1; i--) {
        var byte = Number(buf[i]);
        var f;
        if (flipped) {
          f = onesComp(byte);
        } else if (byte === 0) {
          f = byte;
        } else {
          flipped = true;
          f = twosComp(byte);
        }
        if (f !== 0) {
          sum -= f * Math.pow(256, len - i - 1);
        }
      }
      return sum;
    };
    var pos = (buf) => {
      var len = buf.length;
      var sum = 0;
      for (var i = len - 1; i > -1; i--) {
        var byte = Number(buf[i]);
        if (byte !== 0) {
          sum += byte * Math.pow(256, len - i - 1);
        }
      }
      return sum;
    };
    var onesComp = (byte) => (255 ^ byte) & 255;
    var twosComp = (byte) => (255 ^ byte) + 1 & 255;
  }
});

// ../node_modules/tar/dist/commonjs/types.js
var require_types = __commonJS({
  "../node_modules/tar/dist/commonjs/types.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.code = exports2.name = exports2.normalFsTypes = exports2.isName = exports2.isCode = void 0;
    var isCode = (c) => exports2.name.has(c);
    exports2.isCode = isCode;
    var isName = (c) => exports2.code.has(c);
    exports2.isName = isName;
    exports2.normalFsTypes = /* @__PURE__ */ new Set([
      "0",
      "",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "D"
    ]);
    exports2.name = /* @__PURE__ */ new Map([
      ["0", "File"],
      // same as File
      ["", "OldFile"],
      ["1", "Link"],
      ["2", "SymbolicLink"],
      // Devices and FIFOs aren't fully supported
      // they are parsed, but skipped when unpacking
      ["3", "CharacterDevice"],
      ["4", "BlockDevice"],
      ["5", "Directory"],
      ["6", "FIFO"],
      // same as File
      ["7", "ContiguousFile"],
      // pax headers
      ["g", "GlobalExtendedHeader"],
      ["x", "ExtendedHeader"],
      // vendor-specific stuff
      // skip
      ["A", "SolarisACL"],
      // like 5, but with data, which should be skipped
      ["D", "GNUDumpDir"],
      // metadata only, skip
      ["I", "Inode"],
      // data = link path of next file
      ["K", "NextFileHasLongLinkpath"],
      // data = path of next file
      ["L", "NextFileHasLongPath"],
      // skip
      ["M", "ContinuationFile"],
      // like L
      ["N", "OldGnuLongPath"],
      // skip
      ["S", "SparseFile"],
      // skip
      ["V", "TapeVolumeHeader"],
      // like x
      ["X", "OldExtendedHeader"]
    ]);
    exports2.code = new Map(Array.from(exports2.name).map((kv) => [kv[1], kv[0]]));
  }
});

// ../node_modules/tar/dist/commonjs/header.js
var require_header = __commonJS({
  "../node_modules/tar/dist/commonjs/header.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.Header = void 0;
    var node_path_1 = require("node:path");
    var large = __importStar(require_large_numbers());
    var types = __importStar(require_types());
    var notNegative = (n) => n === void 0 || n < 0 ? void 0 : n;
    var Header = class {
      cksumValid = false;
      needPax = false;
      nullBlock = false;
      block;
      path;
      mode;
      uid;
      gid;
      size;
      cksum;
      #type = "Unsupported";
      linkpath;
      uname;
      gname;
      devmaj = 0;
      devmin = 0;
      atime;
      ctime;
      mtime;
      charset;
      comment;
      constructor(data, off = 0, ex, gex) {
        if (Buffer.isBuffer(data)) {
          this.decode(data, off || 0, ex, gex);
        } else if (data) {
          this.#slurp(data);
        }
      }
      decode(buf, off, ex, gex) {
        if (!off) {
          off = 0;
        }
        if (!buf || !(buf.length >= off + 512)) {
          throw new Error("need 512 bytes for header");
        }
        const t = decString(buf, off + 156, 1);
        const isNormalFS = types.normalFsTypes.has(t);
        const exForFields = isNormalFS ? ex : void 0;
        const gexForFields = isNormalFS ? gex : void 0;
        this.path = exForFields?.path ?? decString(buf, off, 100);
        this.mode = exForFields?.mode ?? gexForFields?.mode ?? decNumber(buf, off + 100, 8);
        this.uid = exForFields?.uid ?? gexForFields?.uid ?? decNumber(buf, off + 108, 8);
        this.gid = exForFields?.gid ?? gexForFields?.gid ?? decNumber(buf, off + 116, 8);
        this.size = notNegative(exForFields?.size ?? gexForFields?.size ?? decNumber(buf, off + 124, 12));
        this.mtime = exForFields?.mtime ?? gexForFields?.mtime ?? decDate(buf, off + 136, 12);
        this.cksum = decNumber(buf, off + 148, 12);
        if (gexForFields)
          this.#slurp(gexForFields, true);
        if (exForFields)
          this.#slurp(exForFields);
        if (types.isCode(t)) {
          this.#type = t || "0";
        }
        if (this.#type === "0" && this.path.slice(-1) === "/") {
          this.#type = "5";
        }
        if (this.#type === "5") {
          this.size = 0;
        }
        this.linkpath = decString(buf, off + 157, 100);
        if (buf.subarray(off + 257, off + 265).toString() === "ustar\x0000") {
          this.uname = exForFields?.uname ?? gexForFields?.uname ?? decString(buf, off + 265, 32);
          this.gname = exForFields?.gname ?? gexForFields?.gname ?? decString(buf, off + 297, 32);
          this.devmaj = exForFields?.devmaj ?? gexForFields?.devmaj ?? decNumber(buf, off + 329, 8) ?? 0;
          this.devmin = exForFields?.devmin ?? gexForFields?.devmin ?? decNumber(buf, off + 337, 8) ?? 0;
          if (buf[off + 475] !== 0) {
            const prefix = decString(buf, off + 345, 155);
            this.path = prefix + "/" + this.path;
          } else {
            const prefix = decString(buf, off + 345, 130);
            if (prefix) {
              this.path = prefix + "/" + this.path;
            }
            this.atime = ex?.atime ?? gex?.atime ?? decDate(buf, off + 476, 12);
            this.ctime = ex?.ctime ?? gex?.ctime ?? decDate(buf, off + 488, 12);
          }
        }
        let sum = 8 * 32;
        for (let i = off; i < off + 148; i++) {
          sum += buf[i];
        }
        for (let i = off + 156; i < off + 512; i++) {
          sum += buf[i];
        }
        this.cksumValid = sum === this.cksum;
        if (this.cksum === void 0 && sum === 8 * 32) {
          this.nullBlock = true;
        }
      }
      #slurp(ex, gex = false) {
        Object.assign(this, Object.fromEntries(Object.entries(ex).filter(([k, v]) => {
          return !(v === null || v === void 0 || k === "size" && Number(v) < 0 || k === "path" && gex || k === "linkpath" && gex || k === "global");
        })));
      }
      encode(buf, off = 0) {
        if (!buf) {
          buf = this.block = Buffer.alloc(512);
        }
        if (this.#type === "Unsupported") {
          this.#type = "0";
        }
        if (!(buf.length >= off + 512)) {
          throw new Error("need 512 bytes for header");
        }
        const prefixSize = this.ctime || this.atime ? 130 : 155;
        const split = splitPrefix(this.path || "", prefixSize);
        const path2 = split[0];
        const prefix = split[1];
        this.needPax = !!split[2];
        this.needPax = encString(buf, off, 100, path2) || this.needPax;
        this.needPax = encNumber(buf, off + 100, 8, this.mode) || this.needPax;
        this.needPax = encNumber(buf, off + 108, 8, this.uid) || this.needPax;
        this.needPax = encNumber(buf, off + 116, 8, this.gid) || this.needPax;
        this.needPax = encNumber(buf, off + 124, 12, this.size) || this.needPax;
        this.needPax = encDate(buf, off + 136, 12, this.mtime) || this.needPax;
        buf[off + 156] = Number(this.#type.codePointAt(0));
        this.needPax = encString(buf, off + 157, 100, this.linkpath) || this.needPax;
        buf.write("ustar\x0000", off + 257, 8);
        this.needPax = encString(buf, off + 265, 32, this.uname) || this.needPax;
        this.needPax = encString(buf, off + 297, 32, this.gname) || this.needPax;
        this.needPax = encNumber(buf, off + 329, 8, this.devmaj) || this.needPax;
        this.needPax = encNumber(buf, off + 337, 8, this.devmin) || this.needPax;
        this.needPax = encString(buf, off + 345, prefixSize, prefix) || this.needPax;
        if (buf[off + 475] !== 0) {
          this.needPax = encString(buf, off + 345, 155, prefix) || this.needPax;
        } else {
          this.needPax = encString(buf, off + 345, 130, prefix) || this.needPax;
          this.needPax = encDate(buf, off + 476, 12, this.atime) || this.needPax;
          this.needPax = encDate(buf, off + 488, 12, this.ctime) || this.needPax;
        }
        let sum = 8 * 32;
        for (let i = off; i < off + 148; i++) {
          sum += buf[i];
        }
        for (let i = off + 156; i < off + 512; i++) {
          sum += buf[i];
        }
        this.cksum = sum;
        encNumber(buf, off + 148, 8, this.cksum);
        this.cksumValid = true;
        return this.needPax;
      }
      get type() {
        return this.#type === "Unsupported" ? this.#type : types.name.get(this.#type);
      }
      get typeKey() {
        return this.#type;
      }
      set type(type) {
        const c = String(types.code.get(type));
        if (types.isCode(c) || c === "Unsupported") {
          this.#type = c;
        } else if (types.isCode(type)) {
          this.#type = type;
        } else {
          throw new TypeError("invalid entry type: " + type);
        }
      }
    };
    exports2.Header = Header;
    var splitPrefix = (p, prefixSize) => {
      const pathSize = 100;
      let pp = p;
      let prefix = "";
      let ret = void 0;
      const root = node_path_1.posix.parse(p).root || ".";
      if (Buffer.byteLength(pp) < pathSize) {
        ret = [pp, prefix, false];
      } else {
        prefix = node_path_1.posix.dirname(pp);
        pp = node_path_1.posix.basename(pp);
        do {
          if (Buffer.byteLength(pp) <= pathSize && Buffer.byteLength(prefix) <= prefixSize) {
            ret = [pp, prefix, false];
          } else if (Buffer.byteLength(pp) > pathSize && Buffer.byteLength(prefix) <= prefixSize) {
            ret = [pp.slice(0, pathSize - 1), prefix, true];
          } else {
            pp = node_path_1.posix.join(node_path_1.posix.basename(prefix), pp);
            prefix = node_path_1.posix.dirname(prefix);
          }
        } while (prefix !== root && ret === void 0);
        if (!ret) {
          ret = [p.slice(0, pathSize - 1), "", true];
        }
      }
      return ret;
    };
    var decString = (buf, off, size) => buf.subarray(off, off + size).toString("utf8").replace(/\0.*/, "");
    var decDate = (buf, off, size) => numToDate(decNumber(buf, off, size));
    var numToDate = (num) => num === void 0 ? void 0 : new Date(num * 1e3);
    var decNumber = (buf, off, size) => Number(buf[off]) & 128 ? large.parse(buf.subarray(off, off + size)) : decSmallNumber(buf, off, size);
    var nanUndef = (value) => isNaN(value) ? void 0 : value;
    var decSmallNumber = (buf, off, size) => nanUndef(parseInt(buf.subarray(off, off + size).toString("utf8").replace(/\0.*$/, "").trim(), 8));
    var MAXNUM = {
      12: 8589934591,
      8: 2097151
    };
    var encNumber = (buf, off, size, num) => num === void 0 ? false : num > MAXNUM[size] || num < 0 ? (large.encode(num, buf.subarray(off, off + size)), true) : (encSmallNumber(buf, off, size, num), false);
    var encSmallNumber = (buf, off, size, num) => buf.write(octalString(num, size), off, size, "ascii");
    var octalString = (num, size) => padOctal(Math.floor(num).toString(8), size);
    var padOctal = (str, size) => (str.length === size - 1 ? str : new Array(size - str.length - 1).join("0") + str + " ") + "\0";
    var encDate = (buf, off, size, date) => date === void 0 ? false : encNumber(buf, off, size, date.getTime() / 1e3);
    var NULLS = new Array(156).join("\0");
    var encString = (buf, off, size, str) => str === void 0 ? false : (buf.write(str + NULLS, off, size, "utf8"), str.length !== Buffer.byteLength(str) || str.length > size);
  }
});

// ../node_modules/tar/dist/commonjs/pax.js
var require_pax = __commonJS({
  "../node_modules/tar/dist/commonjs/pax.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.Pax = void 0;
    var node_path_1 = require("node:path");
    var header_js_1 = require_header();
    var Pax = class _Pax {
      atime;
      mtime;
      ctime;
      charset;
      comment;
      gid;
      uid;
      gname;
      uname;
      linkpath;
      dev;
      ino;
      nlink;
      path;
      size;
      mode;
      global;
      constructor(obj, global2 = false) {
        this.atime = obj.atime;
        this.charset = obj.charset;
        this.comment = obj.comment;
        this.ctime = obj.ctime;
        this.dev = obj.dev;
        this.gid = obj.gid;
        this.global = global2;
        this.gname = obj.gname;
        this.ino = obj.ino;
        this.linkpath = obj.linkpath;
        this.mtime = obj.mtime;
        this.nlink = obj.nlink;
        this.path = obj.path;
        this.size = obj.size;
        this.uid = obj.uid;
        this.uname = obj.uname;
      }
      encode() {
        const body = this.encodeBody();
        if (body === "") {
          return Buffer.allocUnsafe(0);
        }
        const bodyLen = Buffer.byteLength(body);
        const bufLen = 512 * Math.ceil(1 + bodyLen / 512);
        const buf = Buffer.allocUnsafe(bufLen);
        for (let i = 0; i < 512; i++) {
          buf[i] = 0;
        }
        new header_js_1.Header({
          // XXX split the path
          // then the path should be PaxHeader + basename, but less than 99,
          // prepend with the dirname
          /* c8 ignore start */
          path: ("PaxHeader/" + (0, node_path_1.basename)(this.path ?? "")).slice(0, 99),
          /* c8 ignore stop */
          mode: this.mode || 420,
          uid: this.uid,
          gid: this.gid,
          size: bodyLen,
          mtime: this.mtime,
          type: this.global ? "GlobalExtendedHeader" : "ExtendedHeader",
          linkpath: "",
          uname: this.uname || "",
          gname: this.gname || "",
          devmaj: 0,
          devmin: 0,
          atime: this.atime,
          ctime: this.ctime
        }).encode(buf);
        buf.write(body, 512, bodyLen, "utf8");
        for (let i = bodyLen + 512; i < buf.length; i++) {
          buf[i] = 0;
        }
        return buf;
      }
      encodeBody() {
        return this.encodeField("path") + this.encodeField("ctime") + this.encodeField("atime") + this.encodeField("dev") + this.encodeField("ino") + this.encodeField("nlink") + this.encodeField("charset") + this.encodeField("comment") + this.encodeField("gid") + this.encodeField("gname") + this.encodeField("linkpath") + this.encodeField("mtime") + this.encodeField("size") + this.encodeField("uid") + this.encodeField("uname");
      }
      encodeField(field) {
        if (this[field] === void 0) {
          return "";
        }
        const r = this[field];
        const v = r instanceof Date ? r.getTime() / 1e3 : r;
        const s = " " + (field === "dev" || field === "ino" || field === "nlink" ? "SCHILY." : "") + field + "=" + v + "\n";
        const byteLen = Buffer.byteLength(s);
        let digits = Math.floor(Math.log(byteLen) / Math.log(10)) + 1;
        if (byteLen + digits >= Math.pow(10, digits)) {
          digits += 1;
        }
        const len = digits + byteLen;
        return len + s;
      }
      static parse(str, ex, g = false) {
        return new _Pax(merge(parseKV(str), ex), g);
      }
    };
    exports2.Pax = Pax;
    var merge = (a, b) => b ? Object.assign({}, b, a) : a;
    var parseKV = (str) => str.replace(/\n$/, "").split("\n").reduce(parseKVLine, /* @__PURE__ */ Object.create(null));
    var parseKVLine = (set, line) => {
      const n = parseInt(line, 10);
      if (n !== Buffer.byteLength(line) + 1) {
        return set;
      }
      line = line.slice((n + " ").length);
      const kv = line.split("=");
      const r = kv.shift();
      if (!r) {
        return set;
      }
      const k = r.replace(/^SCHILY\.(dev|ino|nlink)/, "$1");
      const v = kv.join("=").replace(/\0.*/, "");
      switch (k) {
        case "path":
        case "linkpath":
        case "type":
        case "charset":
        case "comment":
        case "gname":
        case "uname":
          set[k] = v;
          break;
        case "ctime":
        case "atime":
        case "mtime":
          set[k] = new Date(Number(v) * 1e3);
          break;
        case "size":
          const s = +v;
          if (s >= 0)
            set[k] = s;
          break;
        case "gid":
        case "uid":
        case "dev":
        case "ino":
        case "nlink":
        case "mode":
          set[k] = +v;
          break;
      }
      return set;
    };
  }
});

// ../node_modules/tar/dist/commonjs/normalize-windows-path.js
var require_normalize_windows_path = __commonJS({
  "../node_modules/tar/dist/commonjs/normalize-windows-path.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.normalizeWindowsPath = void 0;
    var platform = process.env.TESTING_TAR_FAKE_PLATFORM || process.platform;
    exports2.normalizeWindowsPath = platform !== "win32" ? (p) => String(p) : (p) => String(p).replaceAll(/\\/g, "/");
  }
});

// ../node_modules/tar/dist/commonjs/read-entry.js
var require_read_entry = __commonJS({
  "../node_modules/tar/dist/commonjs/read-entry.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.ReadEntry = void 0;
    var minipass_1 = require_commonjs3();
    var normalize_windows_path_js_1 = require_normalize_windows_path();
    var ReadEntry = class extends minipass_1.Minipass {
      extended;
      globalExtended;
      header;
      startBlockSize;
      blockRemain;
      remain;
      type;
      meta = false;
      ignore = false;
      path;
      mode;
      uid;
      gid;
      uname;
      gname;
      size = 0;
      mtime;
      atime;
      ctime;
      linkpath;
      dev;
      ino;
      nlink;
      invalid = false;
      absolute;
      unsupported = false;
      constructor(header, ex, gex) {
        super({});
        this.pause();
        this.extended = ex;
        this.globalExtended = gex;
        this.header = header;
        this.remain = header.size ?? 0;
        this.startBlockSize = 512 * Math.ceil(this.remain / 512);
        this.blockRemain = this.startBlockSize;
        this.type = header.type;
        switch (this.type) {
          case "File":
          case "OldFile":
          case "Link":
          case "SymbolicLink":
          case "CharacterDevice":
          case "BlockDevice":
          case "Directory":
          case "FIFO":
          case "ContiguousFile":
          case "GNUDumpDir":
            break;
          case "NextFileHasLongLinkpath":
          case "NextFileHasLongPath":
          case "OldGnuLongPath":
          case "GlobalExtendedHeader":
          case "ExtendedHeader":
          case "OldExtendedHeader":
            this.meta = true;
            break;
          // NOTE: gnutar and bsdtar treat unrecognized types as 'File'
          // it may be worth doing the same, but with a warning.
          default:
            this.ignore = true;
        }
        if (!header.path) {
          throw new Error("no path provided for tar.ReadEntry");
        }
        this.path = (0, normalize_windows_path_js_1.normalizeWindowsPath)(header.path);
        this.mode = header.mode;
        if (this.mode) {
          this.mode = this.mode & 4095;
        }
        this.uid = header.uid;
        this.gid = header.gid;
        this.uname = header.uname;
        this.gname = header.gname;
        this.size = this.remain;
        this.mtime = header.mtime;
        this.atime = header.atime;
        this.ctime = header.ctime;
        this.linkpath = header.linkpath ? (0, normalize_windows_path_js_1.normalizeWindowsPath)(header.linkpath) : void 0;
        this.uname = header.uname;
        this.gname = header.gname;
        if (ex) {
          this.#slurp(ex);
        }
        if (gex) {
          this.#slurp(gex, true);
        }
      }
      write(data) {
        const writeLen = data.length;
        if (writeLen > this.blockRemain) {
          throw new Error("writing more to entry than is appropriate");
        }
        const r = this.remain;
        const br = this.blockRemain;
        this.remain = Math.max(0, r - writeLen);
        this.blockRemain = Math.max(0, br - writeLen);
        if (this.ignore) {
          return true;
        }
        if (r >= writeLen) {
          return super.write(data);
        }
        return super.write(data.subarray(0, r));
      }
      #slurp(ex, gex = false) {
        if (ex.path)
          ex.path = (0, normalize_windows_path_js_1.normalizeWindowsPath)(ex.path);
        if (ex.linkpath)
          ex.linkpath = (0, normalize_windows_path_js_1.normalizeWindowsPath)(ex.linkpath);
        Object.assign(this, Object.fromEntries(Object.entries(ex).filter(([k, v]) => {
          return !(v === null || v === void 0 || k === "path" && gex);
        })));
      }
    };
    exports2.ReadEntry = ReadEntry;
  }
});

// ../node_modules/tar/dist/commonjs/warn-method.js
var require_warn_method = __commonJS({
  "../node_modules/tar/dist/commonjs/warn-method.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.warnMethod = void 0;
    var warnMethod = (self, code, message, data = {}) => {
      if (self.file) {
        data.file = self.file;
      }
      if (self.cwd) {
        data.cwd = self.cwd;
      }
      data.code = message instanceof Error && message.code || code;
      data.tarCode = code;
      if (!self.strict && data.recoverable !== false) {
        if (message instanceof Error) {
          data = Object.assign(message, data);
          message = message.message;
        }
        self.emit("warn", code, message, data);
      } else if (message instanceof Error) {
        self.emit("error", Object.assign(message, data));
      } else {
        self.emit("error", Object.assign(new Error(`${code}: ${message}`), data));
      }
    };
    exports2.warnMethod = warnMethod;
  }
});

// ../node_modules/tar/dist/commonjs/parse.js
var require_parse = __commonJS({
  "../node_modules/tar/dist/commonjs/parse.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.Parser = void 0;
    var events_1 = require("events");
    var minizlib_1 = require_commonjs4();
    var header_js_1 = require_header();
    var pax_js_1 = require_pax();
    var read_entry_js_1 = require_read_entry();
    var warn_method_js_1 = require_warn_method();
    var maxMetaEntrySize = 1024 * 1024;
    var gzipHeader = Buffer.from([31, 139]);
    var zstdHeader = Buffer.from([40, 181, 47, 253]);
    var ZIP_HEADER_LEN = Math.max(gzipHeader.length, zstdHeader.length);
    var STATE = /* @__PURE__ */ Symbol("state");
    var WRITEENTRY = /* @__PURE__ */ Symbol("writeEntry");
    var READENTRY = /* @__PURE__ */ Symbol("readEntry");
    var NEXTENTRY = /* @__PURE__ */ Symbol("nextEntry");
    var PROCESSENTRY = /* @__PURE__ */ Symbol("processEntry");
    var EX = /* @__PURE__ */ Symbol("extendedHeader");
    var GEX = /* @__PURE__ */ Symbol("globalExtendedHeader");
    var META = /* @__PURE__ */ Symbol("meta");
    var EMITMETA = /* @__PURE__ */ Symbol("emitMeta");
    var BUFFER = /* @__PURE__ */ Symbol("buffer");
    var QUEUE = /* @__PURE__ */ Symbol("queue");
    var ENDED = /* @__PURE__ */ Symbol("ended");
    var EMITTEDEND = /* @__PURE__ */ Symbol("emittedEnd");
    var EMIT = /* @__PURE__ */ Symbol("emit");
    var UNZIP = /* @__PURE__ */ Symbol("unzip");
    var CONSUMECHUNK = /* @__PURE__ */ Symbol("consumeChunk");
    var CONSUMECHUNKSUB = /* @__PURE__ */ Symbol("consumeChunkSub");
    var CONSUMEBODY = /* @__PURE__ */ Symbol("consumeBody");
    var CONSUMEMETA = /* @__PURE__ */ Symbol("consumeMeta");
    var CONSUMEHEADER = /* @__PURE__ */ Symbol("consumeHeader");
    var CONSUMING = /* @__PURE__ */ Symbol("consuming");
    var BUFFERCONCAT = /* @__PURE__ */ Symbol("bufferConcat");
    var MAYBEEND = /* @__PURE__ */ Symbol("maybeEnd");
    var WRITING = /* @__PURE__ */ Symbol("writing");
    var ABORTED = /* @__PURE__ */ Symbol("aborted");
    var DONE = /* @__PURE__ */ Symbol("onDone");
    var SAW_VALID_ENTRY = /* @__PURE__ */ Symbol("sawValidEntry");
    var SAW_NULL_BLOCK = /* @__PURE__ */ Symbol("sawNullBlock");
    var SAW_EOF = /* @__PURE__ */ Symbol("sawEOF");
    var CLOSESTREAM = /* @__PURE__ */ Symbol("closeStream");
    var MAX_DECOMPRESSION_RATIO = 1e3;
    var COMPRESSEDBYTESREAD = /* @__PURE__ */ Symbol("compressedBytesRead");
    var DECOMPRESSEDBYTESREAD = /* @__PURE__ */ Symbol("decompressedBytesRead");
    var CHECKDECOMPRESSIONRATIO = /* @__PURE__ */ Symbol("checkDecompressionRatio");
    var noop = () => true;
    var Parser = class extends events_1.EventEmitter {
      file;
      strict;
      maxMetaEntrySize;
      filter;
      brotli;
      zstd;
      maxDecompressionRatio;
      writable = true;
      readable = false;
      [QUEUE] = [];
      [BUFFER];
      [READENTRY];
      [WRITEENTRY];
      [STATE] = "begin";
      [META] = "";
      [EX];
      [GEX];
      [ENDED] = false;
      [UNZIP];
      [ABORTED] = false;
      [SAW_VALID_ENTRY];
      [SAW_NULL_BLOCK] = false;
      [SAW_EOF] = false;
      [WRITING] = false;
      [CONSUMING] = false;
      [EMITTEDEND] = false;
      [COMPRESSEDBYTESREAD] = 0;
      [DECOMPRESSEDBYTESREAD] = 0;
      constructor(opt = {}) {
        super();
        this.file = opt.file || "";
        this.on(DONE, () => {
          if (this[STATE] === "begin" || this[SAW_VALID_ENTRY] === false) {
            this.warn("TAR_BAD_ARCHIVE", "Unrecognized archive format");
          }
        });
        if (opt.ondone) {
          this.on(DONE, opt.ondone);
        } else {
          this.on(DONE, () => {
            this.emit("prefinish");
            this.emit("finish");
            this.emit("end");
          });
        }
        this.strict = !!opt.strict;
        this.maxDecompressionRatio = typeof opt.maxDecompressionRatio === "number" ? opt.maxDecompressionRatio : MAX_DECOMPRESSION_RATIO;
        this.maxMetaEntrySize = opt.maxMetaEntrySize || maxMetaEntrySize;
        this.filter = typeof opt.filter === "function" ? opt.filter : noop;
        const isTBR = opt.file && (opt.file.endsWith(".tar.br") || opt.file.endsWith(".tbr"));
        this.brotli = !(opt.gzip || opt.zstd) && opt.brotli !== void 0 ? opt.brotli : isTBR ? void 0 : false;
        const isTZST = opt.file && (opt.file.endsWith(".tar.zst") || opt.file.endsWith(".tzst"));
        this.zstd = !(opt.gzip || opt.brotli) && opt.zstd !== void 0 ? opt.zstd : isTZST ? true : void 0;
        this.on("end", () => this[CLOSESTREAM]());
        if (typeof opt.onwarn === "function") {
          this.on("warn", opt.onwarn);
        }
        if (typeof opt.onReadEntry === "function") {
          this.on("entry", opt.onReadEntry);
        }
      }
      warn(code, message, data = {}) {
        (0, warn_method_js_1.warnMethod)(this, code, message, data);
      }
      [CONSUMEHEADER](chunk, position) {
        if (this[SAW_VALID_ENTRY] === void 0) {
          this[SAW_VALID_ENTRY] = false;
        }
        let header;
        try {
          header = new header_js_1.Header(chunk, position, this[EX], this[GEX]);
        } catch (er) {
          return this.warn("TAR_ENTRY_INVALID", er);
        }
        if (header.nullBlock) {
          if (this[SAW_NULL_BLOCK]) {
            this[SAW_EOF] = true;
            if (this[STATE] === "begin") {
              this[STATE] = "header";
            }
            this[EMIT]("eof");
          } else {
            this[SAW_NULL_BLOCK] = true;
            this[EMIT]("nullBlock");
          }
        } else {
          this[SAW_NULL_BLOCK] = false;
          if (!header.cksumValid) {
            this.warn("TAR_ENTRY_INVALID", "checksum failure", { header });
          } else if (!header.path) {
            this.warn("TAR_ENTRY_INVALID", "path is required", { header });
          } else {
            const type = header.type;
            if (/^(Symbolic)?Link$/.test(type) && !header.linkpath) {
              this.warn("TAR_ENTRY_INVALID", "linkpath required", {
                header
              });
            } else if (!/^(Symbolic)?Link$/.test(type) && !/^(Global)?ExtendedHeader$/.test(type) && header.linkpath) {
              this.warn("TAR_ENTRY_INVALID", "linkpath forbidden", {
                header
              });
            } else {
              const entry = this[WRITEENTRY] = new read_entry_js_1.ReadEntry(header, this[EX], this[GEX]);
              if (!this[SAW_VALID_ENTRY]) {
                if (entry.remain) {
                  const onend = () => {
                    if (!entry.invalid) {
                      this[SAW_VALID_ENTRY] = true;
                    }
                  };
                  entry.on("end", onend);
                } else {
                  this[SAW_VALID_ENTRY] = true;
                }
              }
              if (entry.meta) {
                if (entry.size > this.maxMetaEntrySize) {
                  entry.ignore = true;
                  this[EMIT]("ignoredEntry", entry);
                  this[STATE] = "ignore";
                  entry.resume();
                } else if (entry.size > 0) {
                  this[META] = "";
                  entry.on("data", (c) => this[META] += c);
                  this[STATE] = "meta";
                }
              } else {
                this[EX] = void 0;
                entry.ignore = entry.ignore || !this.filter(entry.path, entry);
                if (entry.ignore) {
                  this[EMIT]("ignoredEntry", entry);
                  this[STATE] = entry.remain ? "ignore" : "header";
                  entry.resume();
                } else {
                  if (entry.remain) {
                    this[STATE] = "body";
                  } else {
                    this[STATE] = "header";
                    entry.end();
                  }
                  if (!this[READENTRY]) {
                    this[QUEUE].push(entry);
                    this[NEXTENTRY]();
                  } else {
                    this[QUEUE].push(entry);
                  }
                }
              }
            }
          }
        }
      }
      [CLOSESTREAM]() {
        queueMicrotask(() => this.emit("close"));
      }
      [PROCESSENTRY](entry) {
        let go = true;
        if (!entry) {
          this[READENTRY] = void 0;
          go = false;
        } else if (Array.isArray(entry)) {
          const [ev, ...args] = entry;
          this.emit(ev, ...args);
        } else {
          this[READENTRY] = entry;
          this.emit("entry", entry);
          if (!entry.emittedEnd) {
            entry.on("end", () => this[NEXTENTRY]());
            go = false;
          }
        }
        return go;
      }
      [NEXTENTRY]() {
        do {
        } while (this[PROCESSENTRY](this[QUEUE].shift()));
        if (this[QUEUE].length === 0) {
          const re = this[READENTRY];
          const drainNow = !re || re.flowing || re.size === re.remain;
          if (drainNow) {
            if (!this[WRITING]) {
              this.emit("drain");
            }
          } else {
            re.once("drain", () => this.emit("drain"));
          }
        }
      }
      [CONSUMEBODY](chunk, position) {
        const entry = this[WRITEENTRY];
        if (!entry) {
          throw new Error("attempt to consume body without entry??");
        }
        const br = entry.blockRemain ?? 0;
        const c = br >= chunk.length && position === 0 ? chunk : chunk.subarray(position, position + br);
        entry.write(c);
        if (!entry.blockRemain) {
          this[STATE] = "header";
          this[WRITEENTRY] = void 0;
          entry.end();
        }
        return c.length;
      }
      [CONSUMEMETA](chunk, position) {
        const entry = this[WRITEENTRY];
        const ret = this[CONSUMEBODY](chunk, position);
        if (!this[WRITEENTRY] && entry) {
          this[EMITMETA](entry);
        }
        return ret;
      }
      [EMIT](ev, data, extra) {
        if (this[QUEUE].length === 0 && !this[READENTRY]) {
          this.emit(ev, data, extra);
        } else {
          this[QUEUE].push([ev, data, extra]);
        }
      }
      [EMITMETA](entry) {
        this[EMIT]("meta", this[META]);
        switch (entry.type) {
          case "ExtendedHeader":
          case "OldExtendedHeader":
            this[EX] = pax_js_1.Pax.parse(this[META], this[EX], false);
            break;
          case "GlobalExtendedHeader":
            this[GEX] = pax_js_1.Pax.parse(this[META], this[GEX], true);
            break;
          case "NextFileHasLongPath":
          case "OldGnuLongPath": {
            const ex = this[EX] ?? /* @__PURE__ */ Object.create(null);
            this[EX] = ex;
            ex.path = this[META].replace(/\0.*/, "");
            break;
          }
          case "NextFileHasLongLinkpath": {
            const ex = this[EX] || /* @__PURE__ */ Object.create(null);
            this[EX] = ex;
            ex.linkpath = this[META].replace(/\0.*/, "");
            break;
          }
          /* c8 ignore start */
          default:
            throw new Error("unknown meta: " + entry.type);
        }
      }
      abort(error) {
        if (this[ABORTED]) {
          return;
        }
        if (this[UNZIP]) {
          const u = this[UNZIP];
          u.write = () => true;
          u.end = () => u;
          u.emit = () => false;
          u.destroy?.();
        }
        this[ABORTED] = true;
        this.emit("abort", error);
        this.warn("TAR_ABORT", error, { recoverable: false });
      }
      [CHECKDECOMPRESSIONRATIO](chunk) {
        this[DECOMPRESSEDBYTESREAD] += chunk.length;
        const ratio = this[DECOMPRESSEDBYTESREAD] / this[COMPRESSEDBYTESREAD];
        if (ratio > this.maxDecompressionRatio) {
          this.abort(new Error(`max decompression ratio exceeded: ${ratio.toFixed(2)} > ${this.maxDecompressionRatio}`));
          return false;
        }
        return true;
      }
      write(chunk, encoding, cb) {
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (typeof chunk === "string") {
          chunk = Buffer.from(
            chunk,
            /* c8 ignore next */
            typeof encoding === "string" ? encoding : "utf8"
          );
        }
        if (this[ABORTED]) {
          cb?.();
          return false;
        }
        const needSniff = this[UNZIP] === void 0 || this.brotli === void 0 && this[UNZIP] === false;
        if (needSniff && chunk) {
          if (this[BUFFER]) {
            chunk = Buffer.concat([this[BUFFER], chunk]);
            this[BUFFER] = void 0;
          }
          if (chunk.length < ZIP_HEADER_LEN) {
            this[BUFFER] = chunk;
            cb?.();
            return true;
          }
          for (let i = 0; this[UNZIP] === void 0 && i < gzipHeader.length; i++) {
            if (chunk[i] !== gzipHeader[i]) {
              this[UNZIP] = false;
            }
          }
          let isZstd = false;
          if (this[UNZIP] === false && this.zstd !== false) {
            isZstd = true;
            for (let i = 0; i < zstdHeader.length; i++) {
              if (chunk[i] !== zstdHeader[i]) {
                isZstd = false;
                break;
              }
            }
          }
          const maybeBrotli = this.brotli === void 0 && !isZstd;
          if (this[UNZIP] === false && maybeBrotli) {
            if (chunk.length < 512) {
              if (this[ENDED]) {
                this.brotli = true;
              } else {
                this[BUFFER] = chunk;
                cb?.();
                return true;
              }
            } else {
              try {
                new header_js_1.Header(chunk.subarray(0, 512));
                this.brotli = false;
              } catch (_) {
                this.brotli = true;
              }
            }
          }
          if (this[UNZIP] === void 0 || this[UNZIP] === false && (this.brotli || isZstd)) {
            const ended = this[ENDED];
            this[ENDED] = false;
            this[UNZIP] = this[UNZIP] === void 0 ? new minizlib_1.Unzip({}) : isZstd ? new minizlib_1.ZstdDecompress({}) : new minizlib_1.BrotliDecompress({});
            this[UNZIP].on("data", (chunk2) => {
              if (this[CHECKDECOMPRESSIONRATIO](chunk2)) {
                this[CONSUMECHUNK](chunk2);
              }
            });
            this[UNZIP].on("error", (er) => {
              if (!this[ABORTED]) {
                this.abort(er);
              }
            });
            this[UNZIP].on("end", () => {
              this[ENDED] = true;
              this[CONSUMECHUNK]();
            });
            this[WRITING] = true;
            this[COMPRESSEDBYTESREAD] += chunk.length;
            const ret2 = !!this[UNZIP][ended ? "end" : "write"](chunk);
            this[WRITING] = false;
            cb?.();
            return ret2;
          }
        }
        this[WRITING] = true;
        if (this[UNZIP]) {
          this[COMPRESSEDBYTESREAD] += chunk.length;
          this[UNZIP].write(chunk);
        } else {
          this[CONSUMECHUNK](chunk);
        }
        this[WRITING] = false;
        const ret = this[QUEUE].length > 0 ? false : this[READENTRY] ? this[READENTRY].flowing : true;
        if (!ret && this[QUEUE].length === 0) {
          this[READENTRY]?.once("drain", () => this.emit("drain"));
        }
        cb?.();
        return ret;
      }
      [BUFFERCONCAT](c) {
        if (c && !this[ABORTED]) {
          this[BUFFER] = this[BUFFER] ? Buffer.concat([this[BUFFER], c]) : c;
        }
      }
      [MAYBEEND]() {
        if (this[ENDED] && !this[EMITTEDEND] && !this[ABORTED] && !this[CONSUMING]) {
          this[EMITTEDEND] = true;
          const entry = this[WRITEENTRY];
          if (entry?.blockRemain) {
            const have = this[BUFFER] ? this[BUFFER].length : 0;
            this.warn("TAR_BAD_ARCHIVE", `Truncated input (needed ${entry.blockRemain} more bytes, only ${have} available)`, { entry });
            if (this[BUFFER]) {
              entry.write(this[BUFFER]);
            }
            entry.end();
          }
          this[EMIT](DONE);
        }
      }
      [CONSUMECHUNK](chunk) {
        if (this[CONSUMING] && chunk) {
          this[BUFFERCONCAT](chunk);
        } else if (!chunk && !this[BUFFER]) {
          this[MAYBEEND]();
        } else if (chunk) {
          this[CONSUMING] = true;
          if (this[BUFFER]) {
            this[BUFFERCONCAT](chunk);
            const c = this[BUFFER];
            this[BUFFER] = void 0;
            this[CONSUMECHUNKSUB](c);
          } else {
            this[CONSUMECHUNKSUB](chunk);
          }
          while (this[BUFFER] && this[BUFFER]?.length >= 512 && !this[ABORTED] && !this[SAW_EOF]) {
            const c = this[BUFFER];
            this[BUFFER] = void 0;
            this[CONSUMECHUNKSUB](c);
          }
          this[CONSUMING] = false;
        }
        if (!this[BUFFER] || this[ENDED]) {
          this[MAYBEEND]();
        }
      }
      [CONSUMECHUNKSUB](chunk) {
        let position = 0;
        const length = chunk.length;
        while (position + 512 <= length && !this[ABORTED] && !this[SAW_EOF]) {
          switch (this[STATE]) {
            case "begin":
            case "header":
              this[CONSUMEHEADER](chunk, position);
              position += 512;
              break;
            case "ignore":
            case "body":
              position += this[CONSUMEBODY](chunk, position);
              break;
            case "meta":
              position += this[CONSUMEMETA](chunk, position);
              break;
            /* c8 ignore start */
            default:
              throw new Error("invalid state: " + this[STATE]);
          }
        }
        if (position < length) {
          this[BUFFER] = this[BUFFER] ? Buffer.concat([chunk.subarray(position), this[BUFFER]]) : chunk.subarray(position);
        }
      }
      end(chunk, encoding, cb) {
        if (typeof chunk === "function") {
          cb = chunk;
          encoding = void 0;
          chunk = void 0;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (typeof chunk === "string") {
          chunk = Buffer.from(chunk, encoding);
        }
        if (cb)
          this.once("finish", cb);
        if (!this[ABORTED]) {
          if (this[UNZIP]) {
            if (chunk) {
              this[COMPRESSEDBYTESREAD] += chunk.length;
              this[UNZIP].write(chunk);
            }
            this[UNZIP].end();
          } else {
            this[ENDED] = true;
            if (this.brotli === void 0 || this.zstd === void 0)
              chunk = chunk || Buffer.alloc(0);
            if (chunk)
              this.write(chunk);
            this[MAYBEEND]();
          }
        }
        return this;
      }
    };
    exports2.Parser = Parser;
  }
});

// ../node_modules/tar/dist/commonjs/strip-trailing-slashes.js
var require_strip_trailing_slashes = __commonJS({
  "../node_modules/tar/dist/commonjs/strip-trailing-slashes.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.stripTrailingSlashes = void 0;
    var stripTrailingSlashes = (str) => {
      let i = str.length - 1;
      let slashesStart = -1;
      while (i > -1 && str.charAt(i) === "/") {
        slashesStart = i;
        i--;
      }
      return slashesStart === -1 ? str : str.slice(0, slashesStart);
    };
    exports2.stripTrailingSlashes = stripTrailingSlashes;
  }
});

// ../node_modules/tar/dist/commonjs/list.js
var require_list = __commonJS({
  "../node_modules/tar/dist/commonjs/list.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.list = exports2.filesFilter = void 0;
    var fsm = __importStar(require_commonjs2());
    var node_fs_1 = __importDefault(require("node:fs"));
    var path_1 = require("path");
    var make_command_js_1 = require_make_command();
    var parse_js_1 = require_parse();
    var strip_trailing_slashes_js_1 = require_strip_trailing_slashes();
    var onReadEntryFunction = (opt) => {
      const onReadEntry = opt.onReadEntry;
      opt.onReadEntry = onReadEntry ? (e) => {
        onReadEntry(e);
        e.resume();
      } : (e) => e.resume();
    };
    var filesFilter = (opt, files) => {
      const map = new Map(files.map((f) => [(0, strip_trailing_slashes_js_1.stripTrailingSlashes)(f), true]));
      const filter = opt.filter;
      const MAX = 100;
      const mapHas = (file, r = "", depth = 0) => {
        if (depth >= MAX) {
          map.set(file, false);
          return false;
        }
        const root = r || (0, path_1.parse)(file).root || ".";
        let ret;
        if (file === root)
          ret = false;
        else {
          const m = map.get(file);
          ret = m !== void 0 ? m : mapHas((0, path_1.dirname)(file), root, depth + 1);
        }
        map.set(file, ret);
        return ret;
      };
      opt.filter = filter ? (file, entry) => filter(file, entry) && mapHas((0, strip_trailing_slashes_js_1.stripTrailingSlashes)(file)) : (file) => mapHas((0, strip_trailing_slashes_js_1.stripTrailingSlashes)(file));
    };
    exports2.filesFilter = filesFilter;
    var listFileSync = (opt) => {
      const p = new parse_js_1.Parser(opt);
      const file = opt.file;
      let fd;
      try {
        fd = node_fs_1.default.openSync(file, "r");
        const stat = node_fs_1.default.fstatSync(fd);
        const readSize = opt.maxReadSize || 16 * 1024 * 1024;
        if (stat.size < readSize) {
          const buf = Buffer.allocUnsafe(stat.size);
          const read = node_fs_1.default.readSync(fd, buf, 0, stat.size, 0);
          p.end(read === buf.byteLength ? buf : buf.subarray(0, read));
        } else {
          let pos = 0;
          const buf = Buffer.allocUnsafe(readSize);
          while (pos < stat.size) {
            const bytesRead = node_fs_1.default.readSync(fd, buf, 0, readSize, pos);
            if (bytesRead === 0)
              break;
            pos += bytesRead;
            p.write(buf.subarray(0, bytesRead));
          }
          p.end();
        }
      } finally {
        if (typeof fd === "number") {
          try {
            node_fs_1.default.closeSync(fd);
          } catch {
          }
        }
      }
    };
    var listFile = (opt, _files) => {
      const parse = new parse_js_1.Parser(opt);
      const readSize = opt.maxReadSize || 16 * 1024 * 1024;
      const file = opt.file;
      const p = new Promise((resolve, reject) => {
        parse.on("error", reject);
        parse.on("end", resolve);
        node_fs_1.default.stat(file, (er, stat) => {
          if (er) {
            reject(er);
          } else {
            const stream = new fsm.ReadStream(file, {
              readSize,
              size: stat.size
            });
            stream.on("error", reject);
            stream.pipe(parse);
          }
        });
      });
      return p;
    };
    exports2.list = (0, make_command_js_1.makeCommand)(listFileSync, listFile, (opt) => new parse_js_1.Parser(opt), (opt) => new parse_js_1.Parser(opt), (opt, files) => {
      if (files?.length)
        (0, exports2.filesFilter)(opt, files);
      if (!opt.noResume)
        onReadEntryFunction(opt);
    });
  }
});

// ../node_modules/tar/dist/commonjs/mode-fix.js
var require_mode_fix = __commonJS({
  "../node_modules/tar/dist/commonjs/mode-fix.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.modeFix = void 0;
    var modeFix = (mode, isDir, portable) => {
      mode &= 4095;
      if (portable) {
        mode = (mode | 384) & ~18;
      }
      if (isDir) {
        if (mode & 256) {
          mode |= 64;
        }
        if (mode & 32) {
          mode |= 8;
        }
        if (mode & 4) {
          mode |= 1;
        }
      }
      return mode;
    };
    exports2.modeFix = modeFix;
  }
});

// ../node_modules/tar/dist/commonjs/strip-absolute-path.js
var require_strip_absolute_path = __commonJS({
  "../node_modules/tar/dist/commonjs/strip-absolute-path.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.stripAbsolutePath = void 0;
    var node_path_1 = require("node:path");
    var { isAbsolute, parse } = node_path_1.win32;
    var stripAbsolutePath = (path2) => {
      let r = "";
      let parsed = parse(path2);
      while (isAbsolute(path2) || parsed.root) {
        const root = path2.charAt(0) === "/" && path2.slice(0, 4) !== "//?/" ? "/" : parsed.root;
        path2 = path2.slice(root.length);
        r += root;
        parsed = parse(path2);
      }
      return [r, path2];
    };
    exports2.stripAbsolutePath = stripAbsolutePath;
  }
});

// ../node_modules/tar/dist/commonjs/winchars.js
var require_winchars = __commonJS({
  "../node_modules/tar/dist/commonjs/winchars.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.decode = exports2.encode = void 0;
    var raw = ["|", "<", ">", "?", ":"];
    var win = raw.map((char) => String.fromCodePoint(61440 + Number(char.codePointAt(0))));
    var toWin = new Map(raw.map((char, i) => [char, win[i]]));
    var toRaw = new Map(win.map((char, i) => [char, raw[i]]));
    var encode = (s) => raw.reduce((s2, c) => s2.split(c).join(toWin.get(c)), s);
    exports2.encode = encode;
    var decode = (s) => win.reduce((s2, c) => s2.split(c).join(toRaw.get(c)), s);
    exports2.decode = decode;
  }
});

// ../node_modules/tar/dist/commonjs/write-entry.js
var require_write_entry = __commonJS({
  "../node_modules/tar/dist/commonjs/write-entry.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.WriteEntryTar = exports2.WriteEntrySync = exports2.WriteEntry = void 0;
    var fs_1 = __importDefault(require("fs"));
    var minipass_1 = require_commonjs3();
    var path_1 = __importDefault(require("path"));
    var header_js_1 = require_header();
    var mode_fix_js_1 = require_mode_fix();
    var normalize_windows_path_js_1 = require_normalize_windows_path();
    var options_js_1 = require_options();
    var pax_js_1 = require_pax();
    var strip_absolute_path_js_1 = require_strip_absolute_path();
    var strip_trailing_slashes_js_1 = require_strip_trailing_slashes();
    var warn_method_js_1 = require_warn_method();
    var winchars = __importStar(require_winchars());
    var prefixPath = (path2, prefix) => {
      if (!prefix) {
        return (0, normalize_windows_path_js_1.normalizeWindowsPath)(path2);
      }
      path2 = (0, normalize_windows_path_js_1.normalizeWindowsPath)(path2).replace(/^\.(\/|$)/, "");
      return (0, strip_trailing_slashes_js_1.stripTrailingSlashes)(prefix) + "/" + path2;
    };
    var maxReadSize = 16 * 1024 * 1024;
    var PROCESS = /* @__PURE__ */ Symbol("process");
    var FILE = /* @__PURE__ */ Symbol("file");
    var DIRECTORY = /* @__PURE__ */ Symbol("directory");
    var SYMLINK = /* @__PURE__ */ Symbol("symlink");
    var HARDLINK = /* @__PURE__ */ Symbol("hardlink");
    var HEADER = /* @__PURE__ */ Symbol("header");
    var READ = /* @__PURE__ */ Symbol("read");
    var LSTAT = /* @__PURE__ */ Symbol("lstat");
    var ONLSTAT = /* @__PURE__ */ Symbol("onlstat");
    var ONREAD = /* @__PURE__ */ Symbol("onread");
    var ONREADLINK = /* @__PURE__ */ Symbol("onreadlink");
    var OPENFILE = /* @__PURE__ */ Symbol("openfile");
    var ONOPENFILE = /* @__PURE__ */ Symbol("onopenfile");
    var CLOSE = /* @__PURE__ */ Symbol("close");
    var MODE = /* @__PURE__ */ Symbol("mode");
    var AWAITDRAIN = /* @__PURE__ */ Symbol("awaitDrain");
    var ONDRAIN = /* @__PURE__ */ Symbol("ondrain");
    var PREFIX = /* @__PURE__ */ Symbol("prefix");
    var WriteEntry = class extends minipass_1.Minipass {
      path;
      portable;
      myuid = process.getuid && process.getuid() || 0;
      // until node has builtin pwnam functions, this'll have to do
      myuser = process.env.USER || "";
      maxReadSize;
      linkCache;
      statCache;
      preservePaths;
      cwd;
      strict;
      mtime;
      noPax;
      noMtime;
      prefix;
      fd;
      blockLen = 0;
      blockRemain = 0;
      buf;
      pos = 0;
      remain = 0;
      length = 0;
      offset = 0;
      win32;
      absolute;
      header;
      type;
      linkpath;
      stat;
      onWriteEntry;
      #hadError = false;
      constructor(p, opt_ = {}) {
        const opt = (0, options_js_1.dealias)(opt_);
        super();
        this.path = (0, normalize_windows_path_js_1.normalizeWindowsPath)(p);
        this.portable = !!opt.portable;
        this.maxReadSize = opt.maxReadSize || maxReadSize;
        this.linkCache = opt.linkCache || /* @__PURE__ */ new Map();
        this.statCache = opt.statCache || /* @__PURE__ */ new Map();
        this.preservePaths = !!opt.preservePaths;
        this.cwd = (0, normalize_windows_path_js_1.normalizeWindowsPath)(opt.cwd || process.cwd());
        this.strict = !!opt.strict;
        this.noPax = !!opt.noPax;
        this.noMtime = !!opt.noMtime;
        this.mtime = opt.mtime;
        this.prefix = opt.prefix ? (0, normalize_windows_path_js_1.normalizeWindowsPath)(opt.prefix) : void 0;
        this.onWriteEntry = opt.onWriteEntry;
        if (typeof opt.onwarn === "function") {
          this.on("warn", opt.onwarn);
        }
        let pathWarn = false;
        if (!this.preservePaths) {
          const [root, stripped] = (0, strip_absolute_path_js_1.stripAbsolutePath)(this.path);
          if (root && typeof stripped === "string") {
            this.path = stripped;
            pathWarn = root;
          }
        }
        this.win32 = !!opt.win32 || process.platform === "win32";
        if (this.win32) {
          this.path = winchars.decode(this.path.replaceAll(/\\/g, "/"));
          p = p.replaceAll(/\\/g, "/");
        }
        this.absolute = (0, normalize_windows_path_js_1.normalizeWindowsPath)(opt.absolute || path_1.default.resolve(this.cwd, p));
        if (this.path === "") {
          this.path = "./";
        }
        if (pathWarn) {
          this.warn("TAR_ENTRY_INFO", `stripping ${pathWarn} from absolute path`, {
            entry: this,
            path: pathWarn + this.path
          });
        }
        const cs = this.statCache.get(this.absolute);
        if (cs) {
          this[ONLSTAT](cs);
        } else {
          this[LSTAT]();
        }
      }
      warn(code, message, data = {}) {
        return (0, warn_method_js_1.warnMethod)(this, code, message, data);
      }
      emit(ev, ...data) {
        if (ev === "error") {
          this.#hadError = true;
        }
        return super.emit(ev, ...data);
      }
      [LSTAT]() {
        fs_1.default.lstat(this.absolute, (er, stat) => {
          if (er) {
            return this.emit("error", er);
          }
          this[ONLSTAT](stat);
        });
      }
      [ONLSTAT](stat) {
        this.statCache.set(this.absolute, stat);
        this.stat = stat;
        if (!stat.isFile()) {
          stat.size = 0;
        }
        this.type = getType(stat);
        this.emit("stat", stat);
        this[PROCESS]();
      }
      [PROCESS]() {
        switch (this.type) {
          case "File":
            return this[FILE]();
          case "Directory":
            return this[DIRECTORY]();
          case "SymbolicLink":
            return this[SYMLINK]();
          // unsupported types are ignored.
          default:
            return this.end();
        }
      }
      [MODE](mode) {
        return (0, mode_fix_js_1.modeFix)(mode, this.type === "Directory", this.portable);
      }
      [PREFIX](path2) {
        return prefixPath(path2, this.prefix);
      }
      [HEADER]() {
        if (!this.stat) {
          throw new Error("cannot write header before stat");
        }
        if (this.type === "Directory" && this.portable) {
          this.noMtime = true;
        }
        this.onWriteEntry?.(this);
        this.header = new header_js_1.Header({
          path: this[PREFIX](this.path),
          // only apply the prefix to hard links.
          linkpath: this.type === "Link" && this.linkpath !== void 0 ? this[PREFIX](this.linkpath) : this.linkpath,
          // only the permissions and setuid/setgid/sticky bitflags
          // not the higher-order bits that specify file type
          mode: this[MODE](this.stat.mode),
          uid: this.portable ? void 0 : this.stat.uid,
          gid: this.portable ? void 0 : this.stat.gid,
          size: this.stat.size,
          mtime: this.noMtime ? void 0 : this.mtime || this.stat.mtime,
          /* c8 ignore next */
          type: this.type === "Unsupported" ? void 0 : this.type,
          uname: this.portable ? void 0 : this.stat.uid === this.myuid ? this.myuser : "",
          atime: this.portable ? void 0 : this.stat.atime,
          ctime: this.portable ? void 0 : this.stat.ctime
        });
        if (this.header.encode() && !this.noPax) {
          super.write(new pax_js_1.Pax({
            atime: this.portable ? void 0 : this.header.atime,
            ctime: this.portable ? void 0 : this.header.ctime,
            gid: this.portable ? void 0 : this.header.gid,
            mtime: this.noMtime ? void 0 : this.mtime || this.header.mtime,
            path: this[PREFIX](this.path),
            linkpath: this.type === "Link" && this.linkpath !== void 0 ? this[PREFIX](this.linkpath) : this.linkpath,
            size: this.header.size,
            uid: this.portable ? void 0 : this.header.uid,
            uname: this.portable ? void 0 : this.header.uname,
            dev: this.portable ? void 0 : this.stat.dev,
            ino: this.portable ? void 0 : this.stat.ino,
            nlink: this.portable ? void 0 : this.stat.nlink
          }).encode());
        }
        const block = this.header?.block;
        if (!block) {
          throw new Error("failed to encode header");
        }
        super.write(block);
      }
      [DIRECTORY]() {
        if (!this.stat) {
          throw new Error("cannot create directory entry without stat");
        }
        if (this.path.slice(-1) !== "/") {
          this.path += "/";
        }
        this.stat.size = 0;
        this[HEADER]();
        this.end();
      }
      [SYMLINK]() {
        fs_1.default.readlink(this.absolute, (er, linkpath) => {
          if (er) {
            return this.emit("error", er);
          }
          this[ONREADLINK](linkpath);
        });
      }
      [ONREADLINK](linkpath) {
        this.linkpath = (0, normalize_windows_path_js_1.normalizeWindowsPath)(linkpath);
        this[HEADER]();
        this.end();
      }
      [HARDLINK](linkpath) {
        if (!this.stat) {
          throw new Error("cannot create link entry without stat");
        }
        this.type = "Link";
        this.linkpath = (0, normalize_windows_path_js_1.normalizeWindowsPath)(path_1.default.relative(this.cwd, linkpath));
        this.stat.size = 0;
        this[HEADER]();
        this.end();
      }
      [FILE]() {
        if (!this.stat) {
          throw new Error("cannot create file entry without stat");
        }
        if (this.stat.nlink > 1) {
          const linkKey = `${this.stat.dev}:${this.stat.ino}`;
          const linkpath = this.linkCache.get(linkKey);
          if (linkpath?.indexOf(this.cwd) === 0) {
            return this[HARDLINK](linkpath);
          }
          this.linkCache.set(linkKey, this.absolute);
        }
        this[HEADER]();
        if (this.stat.size === 0) {
          return this.end();
        }
        this[OPENFILE]();
      }
      [OPENFILE]() {
        fs_1.default.open(this.absolute, "r", (er, fd) => {
          if (er) {
            return this.emit("error", er);
          }
          this[ONOPENFILE](fd);
        });
      }
      [ONOPENFILE](fd) {
        this.fd = fd;
        if (this.#hadError) {
          return this[CLOSE]();
        }
        if (!this.stat) {
          throw new Error("should stat before calling onopenfile");
        }
        this.blockLen = 512 * Math.ceil(this.stat.size / 512);
        this.blockRemain = this.blockLen;
        const bufLen = Math.min(this.blockLen, this.maxReadSize);
        this.buf = Buffer.allocUnsafe(bufLen);
        this.offset = 0;
        this.pos = 0;
        this.remain = this.stat.size;
        this.length = this.buf.length;
        this[READ]();
      }
      [READ]() {
        const { fd, buf, offset, length, pos } = this;
        if (fd === void 0 || buf === void 0) {
          throw new Error("cannot read file without first opening");
        }
        fs_1.default.read(fd, buf, offset, length, pos, (er, bytesRead) => {
          if (er) {
            return this[CLOSE](() => this.emit("error", er));
          }
          this[ONREAD](bytesRead);
        });
      }
      /* c8 ignore start */
      [CLOSE](cb = () => {
      }) {
        if (this.fd !== void 0)
          fs_1.default.close(this.fd, cb);
      }
      [ONREAD](bytesRead) {
        if (bytesRead <= 0 && this.remain > 0) {
          const er = Object.assign(new Error("encountered unexpected EOF"), {
            path: this.absolute,
            syscall: "read",
            code: "EOF"
          });
          return this[CLOSE](() => this.emit("error", er));
        }
        if (bytesRead > this.remain) {
          const er = Object.assign(new Error("did not encounter expected EOF"), {
            path: this.absolute,
            syscall: "read",
            code: "EOF"
          });
          return this[CLOSE](() => this.emit("error", er));
        }
        if (!this.buf) {
          throw new Error("should have created buffer prior to reading");
        }
        if (bytesRead === this.remain) {
          for (let i = bytesRead; i < this.length && bytesRead < this.blockRemain; i++) {
            this.buf[i + this.offset] = 0;
            bytesRead++;
            this.remain++;
          }
        }
        const chunk = this.offset === 0 && bytesRead === this.buf.length ? this.buf : this.buf.subarray(this.offset, this.offset + bytesRead);
        const flushed = this.write(chunk);
        if (!flushed) {
          this[AWAITDRAIN](() => this[ONDRAIN]());
        } else {
          this[ONDRAIN]();
        }
      }
      [AWAITDRAIN](cb) {
        this.once("drain", cb);
      }
      write(chunk, encoding, cb) {
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (typeof chunk === "string") {
          chunk = Buffer.from(chunk, typeof encoding === "string" ? encoding : "utf8");
        }
        if (this.blockRemain < chunk.length) {
          const er = Object.assign(new Error("writing more data than expected"), {
            path: this.absolute
          });
          return this.emit("error", er);
        }
        this.remain -= chunk.length;
        this.blockRemain -= chunk.length;
        this.pos += chunk.length;
        this.offset += chunk.length;
        return super.write(chunk, null, cb);
      }
      [ONDRAIN]() {
        if (!this.remain) {
          if (this.blockRemain) {
            super.write(Buffer.alloc(this.blockRemain));
          }
          return this[CLOSE]((er) => er ? this.emit("error", er) : this.end());
        }
        if (!this.buf) {
          throw new Error("buffer lost somehow in ONDRAIN");
        }
        if (this.offset >= this.length) {
          this.buf = Buffer.allocUnsafe(Math.min(this.blockRemain, this.buf.length));
          this.offset = 0;
        }
        this.length = this.buf.length - this.offset;
        this[READ]();
      }
    };
    exports2.WriteEntry = WriteEntry;
    var WriteEntrySync = class extends WriteEntry {
      sync = true;
      [LSTAT]() {
        this[ONLSTAT](fs_1.default.lstatSync(this.absolute));
      }
      [SYMLINK]() {
        this[ONREADLINK](fs_1.default.readlinkSync(this.absolute));
      }
      [OPENFILE]() {
        this[ONOPENFILE](fs_1.default.openSync(this.absolute, "r"));
      }
      [READ]() {
        let threw = true;
        try {
          const { fd, buf, offset, length, pos } = this;
          if (fd === void 0 || buf === void 0) {
            throw new Error("fd and buf must be set in READ method");
          }
          const bytesRead = fs_1.default.readSync(fd, buf, offset, length, pos);
          this[ONREAD](bytesRead);
          threw = false;
        } finally {
          if (threw) {
            try {
              this[CLOSE](() => {
              });
            } catch {
            }
          }
        }
      }
      [AWAITDRAIN](cb) {
        cb();
      }
      /* c8 ignore start */
      [CLOSE](cb = () => {
      }) {
        if (this.fd !== void 0)
          fs_1.default.closeSync(this.fd);
        cb();
      }
    };
    exports2.WriteEntrySync = WriteEntrySync;
    var WriteEntryTar = class extends minipass_1.Minipass {
      blockLen = 0;
      blockRemain = 0;
      buf = 0;
      pos = 0;
      remain = 0;
      length = 0;
      preservePaths;
      portable;
      strict;
      noPax;
      noMtime;
      readEntry;
      type;
      prefix;
      path;
      mode;
      uid;
      gid;
      uname;
      gname;
      header;
      mtime;
      atime;
      ctime;
      linkpath;
      size;
      onWriteEntry;
      warn(code, message, data = {}) {
        return (0, warn_method_js_1.warnMethod)(this, code, message, data);
      }
      constructor(readEntry, opt_ = {}) {
        const opt = (0, options_js_1.dealias)(opt_);
        super();
        this.preservePaths = !!opt.preservePaths;
        this.portable = !!opt.portable;
        this.strict = !!opt.strict;
        this.noPax = !!opt.noPax;
        this.noMtime = !!opt.noMtime;
        this.onWriteEntry = opt.onWriteEntry;
        this.readEntry = readEntry;
        const { type } = readEntry;
        if (type === "Unsupported") {
          throw new Error("writing entry that should be ignored");
        }
        this.type = type;
        if (this.type === "Directory" && this.portable) {
          this.noMtime = true;
        }
        this.prefix = opt.prefix;
        this.path = (0, normalize_windows_path_js_1.normalizeWindowsPath)(readEntry.path);
        this.mode = readEntry.mode !== void 0 ? this[MODE](readEntry.mode) : void 0;
        this.uid = this.portable ? void 0 : readEntry.uid;
        this.gid = this.portable ? void 0 : readEntry.gid;
        this.uname = this.portable ? void 0 : readEntry.uname;
        this.gname = this.portable ? void 0 : readEntry.gname;
        this.size = readEntry.size;
        this.mtime = this.noMtime ? void 0 : opt.mtime || readEntry.mtime;
        this.atime = this.portable ? void 0 : readEntry.atime;
        this.ctime = this.portable ? void 0 : readEntry.ctime;
        this.linkpath = readEntry.linkpath !== void 0 ? (0, normalize_windows_path_js_1.normalizeWindowsPath)(readEntry.linkpath) : void 0;
        if (typeof opt.onwarn === "function") {
          this.on("warn", opt.onwarn);
        }
        let pathWarn = false;
        if (!this.preservePaths) {
          const [root, stripped] = (0, strip_absolute_path_js_1.stripAbsolutePath)(this.path);
          if (root && typeof stripped === "string") {
            this.path = stripped;
            pathWarn = root;
          }
        }
        this.remain = readEntry.size;
        this.blockRemain = readEntry.startBlockSize;
        this.onWriteEntry?.(this);
        this.header = new header_js_1.Header({
          path: this[PREFIX](this.path),
          linkpath: this.type === "Link" && this.linkpath !== void 0 ? this[PREFIX](this.linkpath) : this.linkpath,
          // only the permissions and setuid/setgid/sticky bitflags
          // not the higher-order bits that specify file type
          mode: this.mode,
          uid: this.portable ? void 0 : this.uid,
          gid: this.portable ? void 0 : this.gid,
          size: this.size,
          mtime: this.noMtime ? void 0 : this.mtime,
          type: this.type,
          uname: this.portable ? void 0 : this.uname,
          atime: this.portable ? void 0 : this.atime,
          ctime: this.portable ? void 0 : this.ctime
        });
        if (pathWarn) {
          this.warn("TAR_ENTRY_INFO", `stripping ${pathWarn} from absolute path`, {
            entry: this,
            path: pathWarn + this.path
          });
        }
        if (this.header.encode() && !this.noPax) {
          super.write(new pax_js_1.Pax({
            atime: this.portable ? void 0 : this.atime,
            ctime: this.portable ? void 0 : this.ctime,
            gid: this.portable ? void 0 : this.gid,
            mtime: this.noMtime ? void 0 : this.mtime,
            path: this[PREFIX](this.path),
            linkpath: this.type === "Link" && this.linkpath !== void 0 ? this[PREFIX](this.linkpath) : this.linkpath,
            size: this.size,
            uid: this.portable ? void 0 : this.uid,
            uname: this.portable ? void 0 : this.uname,
            dev: this.portable ? void 0 : this.readEntry.dev,
            ino: this.portable ? void 0 : this.readEntry.ino,
            nlink: this.portable ? void 0 : this.readEntry.nlink
          }).encode());
        }
        const b = this.header?.block;
        if (!b)
          throw new Error("failed to encode header");
        super.write(b);
        readEntry.pipe(this);
      }
      [PREFIX](path2) {
        return prefixPath(path2, this.prefix);
      }
      [MODE](mode) {
        return (0, mode_fix_js_1.modeFix)(mode, this.type === "Directory", this.portable);
      }
      write(chunk, encoding, cb) {
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (typeof chunk === "string") {
          chunk = Buffer.from(chunk, typeof encoding === "string" ? encoding : "utf8");
        }
        const writeLen = chunk.length;
        if (writeLen > this.blockRemain) {
          throw new Error("writing more to entry than is appropriate");
        }
        this.blockRemain -= writeLen;
        return super.write(chunk, cb);
      }
      end(chunk, encoding, cb) {
        if (this.blockRemain) {
          super.write(Buffer.alloc(this.blockRemain));
        }
        if (typeof chunk === "function") {
          cb = chunk;
          encoding = void 0;
          chunk = void 0;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (typeof chunk === "string") {
          chunk = Buffer.from(chunk, encoding ?? "utf8");
        }
        if (cb)
          this.once("finish", cb);
        if (chunk)
          super.end(chunk, cb);
        else
          super.end(cb);
        return this;
      }
    };
    exports2.WriteEntryTar = WriteEntryTar;
    var getType = (stat) => stat.isFile() ? "File" : stat.isDirectory() ? "Directory" : stat.isSymbolicLink() ? "SymbolicLink" : "Unsupported";
  }
});

// ../node_modules/yallist/dist/commonjs/index.js
var require_commonjs5 = __commonJS({
  "../node_modules/yallist/dist/commonjs/index.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.Node = exports2.Yallist = void 0;
    var Yallist = class _Yallist {
      tail;
      head;
      length = 0;
      static create(list = []) {
        return new _Yallist(list);
      }
      constructor(list = []) {
        for (const item of list) {
          this.push(item);
        }
      }
      *[Symbol.iterator]() {
        for (let walker = this.head; walker; walker = walker.next) {
          yield walker.value;
        }
      }
      removeNode(node) {
        if (node.list !== this) {
          throw new Error("removing node which does not belong to this list");
        }
        const next = node.next;
        const prev = node.prev;
        if (next) {
          next.prev = prev;
        }
        if (prev) {
          prev.next = next;
        }
        if (node === this.head) {
          this.head = next;
        }
        if (node === this.tail) {
          this.tail = prev;
        }
        this.length--;
        node.next = void 0;
        node.prev = void 0;
        node.list = void 0;
        return next;
      }
      unshiftNode(node) {
        if (node === this.head) {
          return;
        }
        if (node.list) {
          node.list.removeNode(node);
        }
        const head = this.head;
        node.list = this;
        node.next = head;
        if (head) {
          head.prev = node;
        }
        this.head = node;
        if (!this.tail) {
          this.tail = node;
        }
        this.length++;
      }
      pushNode(node) {
        if (node === this.tail) {
          return;
        }
        if (node.list) {
          node.list.removeNode(node);
        }
        const tail = this.tail;
        node.list = this;
        node.prev = tail;
        if (tail) {
          tail.next = node;
        }
        this.tail = node;
        if (!this.head) {
          this.head = node;
        }
        this.length++;
      }
      push(...args) {
        for (let i = 0, l = args.length; i < l; i++) {
          push(this, args[i]);
        }
        return this.length;
      }
      unshift(...args) {
        for (var i = 0, l = args.length; i < l; i++) {
          unshift(this, args[i]);
        }
        return this.length;
      }
      pop() {
        if (!this.tail) {
          return void 0;
        }
        const res = this.tail.value;
        const t = this.tail;
        this.tail = this.tail.prev;
        if (this.tail) {
          this.tail.next = void 0;
        } else {
          this.head = void 0;
        }
        t.list = void 0;
        this.length--;
        return res;
      }
      shift() {
        if (!this.head) {
          return void 0;
        }
        const res = this.head.value;
        const h = this.head;
        this.head = this.head.next;
        if (this.head) {
          this.head.prev = void 0;
        } else {
          this.tail = void 0;
        }
        h.list = void 0;
        this.length--;
        return res;
      }
      forEach(fn, thisp) {
        thisp = thisp || this;
        for (let walker = this.head, i = 0; !!walker; i++) {
          fn.call(thisp, walker.value, i, this);
          walker = walker.next;
        }
      }
      forEachReverse(fn, thisp) {
        thisp = thisp || this;
        for (let walker = this.tail, i = this.length - 1; !!walker; i--) {
          fn.call(thisp, walker.value, i, this);
          walker = walker.prev;
        }
      }
      get(n) {
        let i = 0;
        let walker = this.head;
        for (; !!walker && i < n; i++) {
          walker = walker.next;
        }
        if (i === n && !!walker) {
          return walker.value;
        }
      }
      getReverse(n) {
        let i = 0;
        let walker = this.tail;
        for (; !!walker && i < n; i++) {
          walker = walker.prev;
        }
        if (i === n && !!walker) {
          return walker.value;
        }
      }
      map(fn, thisp) {
        thisp = thisp || this;
        const res = new _Yallist();
        for (let walker = this.head; !!walker; ) {
          res.push(fn.call(thisp, walker.value, this));
          walker = walker.next;
        }
        return res;
      }
      mapReverse(fn, thisp) {
        thisp = thisp || this;
        var res = new _Yallist();
        for (let walker = this.tail; !!walker; ) {
          res.push(fn.call(thisp, walker.value, this));
          walker = walker.prev;
        }
        return res;
      }
      reduce(fn, initial) {
        let acc;
        let walker = this.head;
        if (arguments.length > 1) {
          acc = initial;
        } else if (this.head) {
          walker = this.head.next;
          acc = this.head.value;
        } else {
          throw new TypeError("Reduce of empty list with no initial value");
        }
        for (var i = 0; !!walker; i++) {
          acc = fn(acc, walker.value, i);
          walker = walker.next;
        }
        return acc;
      }
      reduceReverse(fn, initial) {
        let acc;
        let walker = this.tail;
        if (arguments.length > 1) {
          acc = initial;
        } else if (this.tail) {
          walker = this.tail.prev;
          acc = this.tail.value;
        } else {
          throw new TypeError("Reduce of empty list with no initial value");
        }
        for (let i = this.length - 1; !!walker; i--) {
          acc = fn(acc, walker.value, i);
          walker = walker.prev;
        }
        return acc;
      }
      toArray() {
        const arr = new Array(this.length);
        for (let i = 0, walker = this.head; !!walker; i++) {
          arr[i] = walker.value;
          walker = walker.next;
        }
        return arr;
      }
      toArrayReverse() {
        const arr = new Array(this.length);
        for (let i = 0, walker = this.tail; !!walker; i++) {
          arr[i] = walker.value;
          walker = walker.prev;
        }
        return arr;
      }
      slice(from = 0, to = this.length) {
        if (to < 0) {
          to += this.length;
        }
        if (from < 0) {
          from += this.length;
        }
        const ret = new _Yallist();
        if (to < from || to < 0) {
          return ret;
        }
        if (from < 0) {
          from = 0;
        }
        if (to > this.length) {
          to = this.length;
        }
        let walker = this.head;
        let i = 0;
        for (i = 0; !!walker && i < from; i++) {
          walker = walker.next;
        }
        for (; !!walker && i < to; i++, walker = walker.next) {
          ret.push(walker.value);
        }
        return ret;
      }
      sliceReverse(from = 0, to = this.length) {
        if (to < 0) {
          to += this.length;
        }
        if (from < 0) {
          from += this.length;
        }
        const ret = new _Yallist();
        if (to < from || to < 0) {
          return ret;
        }
        if (from < 0) {
          from = 0;
        }
        if (to > this.length) {
          to = this.length;
        }
        let i = this.length;
        let walker = this.tail;
        for (; !!walker && i > to; i--) {
          walker = walker.prev;
        }
        for (; !!walker && i > from; i--, walker = walker.prev) {
          ret.push(walker.value);
        }
        return ret;
      }
      splice(start, deleteCount = 0, ...nodes) {
        if (start > this.length) {
          start = this.length - 1;
        }
        if (start < 0) {
          start = this.length + start;
        }
        let walker = this.head;
        for (let i = 0; !!walker && i < start; i++) {
          walker = walker.next;
        }
        const ret = [];
        for (let i = 0; !!walker && i < deleteCount; i++) {
          ret.push(walker.value);
          walker = this.removeNode(walker);
        }
        if (!walker) {
          walker = this.tail;
        } else if (walker !== this.tail) {
          walker = walker.prev;
        }
        for (const v of nodes) {
          walker = insertAfter(this, walker, v);
        }
        return ret;
      }
      reverse() {
        const head = this.head;
        const tail = this.tail;
        for (let walker = head; !!walker; walker = walker.prev) {
          const p = walker.prev;
          walker.prev = walker.next;
          walker.next = p;
        }
        this.head = tail;
        this.tail = head;
        return this;
      }
    };
    exports2.Yallist = Yallist;
    function insertAfter(self, node, value) {
      const prev = node;
      const next = node ? node.next : self.head;
      const inserted = new Node(value, prev, next, self);
      if (inserted.next === void 0) {
        self.tail = inserted;
      }
      if (inserted.prev === void 0) {
        self.head = inserted;
      }
      self.length++;
      return inserted;
    }
    function push(self, item) {
      self.tail = new Node(item, self.tail, void 0, self);
      if (!self.head) {
        self.head = self.tail;
      }
      self.length++;
    }
    function unshift(self, item) {
      self.head = new Node(item, void 0, self.head, self);
      if (!self.tail) {
        self.tail = self.head;
      }
      self.length++;
    }
    var Node = class {
      list;
      next;
      prev;
      value;
      constructor(value, prev, next, list) {
        this.list = list;
        this.value = value;
        if (prev) {
          prev.next = this;
          this.prev = prev;
        } else {
          this.prev = void 0;
        }
        if (next) {
          next.prev = this;
          this.next = next;
        } else {
          this.next = void 0;
        }
      }
    };
    exports2.Node = Node;
  }
});

// ../node_modules/tar/dist/commonjs/pack.js
var require_pack = __commonJS({
  "../node_modules/tar/dist/commonjs/pack.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.PackSync = exports2.Pack = exports2.PackJob = void 0;
    var fs_1 = __importDefault(require("fs"));
    var write_entry_js_1 = require_write_entry();
    var PackJob = class {
      path;
      absolute;
      entry;
      stat;
      readdir;
      pending = false;
      pendingLink = false;
      ignore = false;
      piped = false;
      constructor(path2, absolute) {
        this.path = path2 || "./";
        this.absolute = absolute;
      }
    };
    exports2.PackJob = PackJob;
    var minipass_1 = require_commonjs3();
    var zlib = __importStar(require_commonjs4());
    var yallist_1 = require_commonjs5();
    var warn_method_js_1 = require_warn_method();
    var EOF = Buffer.alloc(1024);
    var ONSTAT = /* @__PURE__ */ Symbol("onStat");
    var ENDED = /* @__PURE__ */ Symbol("ended");
    var QUEUE = /* @__PURE__ */ Symbol("queue");
    var PENDINGLINKS = /* @__PURE__ */ Symbol("pendingLinks");
    var CURRENT = /* @__PURE__ */ Symbol("current");
    var PROCESS = /* @__PURE__ */ Symbol("process");
    var PROCESSING = /* @__PURE__ */ Symbol("processing");
    var PROCESSJOB = /* @__PURE__ */ Symbol("processJob");
    var JOBS = /* @__PURE__ */ Symbol("jobs");
    var JOBDONE = /* @__PURE__ */ Symbol("jobDone");
    var ADDFSENTRY = /* @__PURE__ */ Symbol("addFSEntry");
    var ADDTARENTRY = /* @__PURE__ */ Symbol("addTarEntry");
    var STAT = /* @__PURE__ */ Symbol("stat");
    var READDIR = /* @__PURE__ */ Symbol("readdir");
    var ONREADDIR = /* @__PURE__ */ Symbol("onreaddir");
    var PIPE = /* @__PURE__ */ Symbol("pipe");
    var ENTRY = /* @__PURE__ */ Symbol("entry");
    var ENTRYOPT = /* @__PURE__ */ Symbol("entryOpt");
    var WRITEENTRYCLASS = /* @__PURE__ */ Symbol("writeEntryClass");
    var WRITE = /* @__PURE__ */ Symbol("write");
    var ONDRAIN = /* @__PURE__ */ Symbol("ondrain");
    var path_1 = __importDefault(require("path"));
    var normalize_windows_path_js_1 = require_normalize_windows_path();
    var Pack = class extends minipass_1.Minipass {
      sync = false;
      opt;
      cwd;
      maxReadSize;
      preservePaths;
      strict;
      noPax;
      prefix;
      linkCache;
      statCache;
      file;
      portable;
      zip;
      readdirCache;
      noDirRecurse;
      follow;
      noMtime;
      mtime;
      filter;
      jobs;
      [WRITEENTRYCLASS];
      onWriteEntry;
      // Note: we actually DO need a linked list here, because we
      // shift() to update the head of the list where we start, but still
      // while that happens, need to know what the next item in the queue
      // will be. Since we do multiple jobs in parallel, it's not as simple
      // as just an Array.shift(), since that would lose the information about
      // the next job in the list. We could add a .next field on the PackJob
      // class, but then we'd have to be tracking the tail of the queue the
      // whole time, and Yallist just does that for us anyway.
      [QUEUE];
      [PENDINGLINKS] = /* @__PURE__ */ new Map();
      [JOBS] = 0;
      [PROCESSING] = false;
      [ENDED] = false;
      constructor(opt = {}) {
        super();
        this.opt = opt;
        this.file = opt.file || "";
        this.cwd = opt.cwd || process.cwd();
        this.maxReadSize = opt.maxReadSize;
        this.preservePaths = !!opt.preservePaths;
        this.strict = !!opt.strict;
        this.noPax = !!opt.noPax;
        this.prefix = (0, normalize_windows_path_js_1.normalizeWindowsPath)(opt.prefix || "");
        this.linkCache = opt.linkCache || /* @__PURE__ */ new Map();
        this.statCache = opt.statCache || /* @__PURE__ */ new Map();
        this.readdirCache = opt.readdirCache || /* @__PURE__ */ new Map();
        this.onWriteEntry = opt.onWriteEntry;
        this[WRITEENTRYCLASS] = write_entry_js_1.WriteEntry;
        if (typeof opt.onwarn === "function") {
          this.on("warn", opt.onwarn);
        }
        this.portable = !!opt.portable;
        if (opt.gzip || opt.brotli || opt.zstd) {
          if ((opt.gzip ? 1 : 0) + (opt.brotli ? 1 : 0) + (opt.zstd ? 1 : 0) > 1) {
            throw new TypeError("gzip, brotli, zstd are mutually exclusive");
          }
          if (opt.gzip) {
            if (typeof opt.gzip !== "object") {
              opt.gzip = {};
            }
            if (this.portable) {
              opt.gzip.portable = true;
            }
            this.zip = new zlib.Gzip(opt.gzip);
          }
          if (opt.brotli) {
            if (typeof opt.brotli !== "object") {
              opt.brotli = {};
            }
            this.zip = new zlib.BrotliCompress(opt.brotli);
          }
          if (opt.zstd) {
            if (typeof opt.zstd !== "object") {
              opt.zstd = {};
            }
            this.zip = new zlib.ZstdCompress(opt.zstd);
          }
          if (!this.zip)
            throw new Error("impossible");
          const zip = this.zip;
          zip.on("data", (chunk) => super.write(chunk));
          zip.on("end", () => super.end());
          zip.on("drain", () => this[ONDRAIN]());
          this.on("resume", () => zip.resume());
        } else {
          this.on("drain", this[ONDRAIN]);
        }
        this.noDirRecurse = !!opt.noDirRecurse;
        this.follow = !!opt.follow;
        this.noMtime = !!opt.noMtime;
        if (opt.mtime)
          this.mtime = opt.mtime;
        this.filter = typeof opt.filter === "function" ? opt.filter : () => true;
        this[QUEUE] = new yallist_1.Yallist();
        this[JOBS] = 0;
        this.jobs = Number(opt.jobs) || 4;
        this[PROCESSING] = false;
        this[ENDED] = false;
      }
      [WRITE](chunk) {
        return super.write(chunk);
      }
      add(path2) {
        this.write(path2);
        return this;
      }
      end(path2, encoding, cb) {
        if (typeof path2 === "function") {
          cb = path2;
          path2 = void 0;
        }
        if (typeof encoding === "function") {
          cb = encoding;
          encoding = void 0;
        }
        if (path2) {
          this.add(path2);
        }
        this[ENDED] = true;
        this[PROCESS]();
        if (cb)
          cb();
        return this;
      }
      write(path2) {
        if (this[ENDED]) {
          throw new Error("write after end");
        }
        if (typeof path2 === "string") {
          this[ADDFSENTRY](path2);
        } else {
          this[ADDTARENTRY](path2);
        }
        return this.flowing;
      }
      [ADDTARENTRY](p) {
        const absolute = (0, normalize_windows_path_js_1.normalizeWindowsPath)(path_1.default.resolve(this.cwd, p.path));
        if (!this.filter(p.path, p)) {
          p.resume();
        } else {
          const job = new PackJob(p.path, absolute);
          job.entry = new write_entry_js_1.WriteEntryTar(p, this[ENTRYOPT](job));
          job.entry.on("end", () => this[JOBDONE](job));
          this[JOBS] += 1;
          this[QUEUE].push(job);
        }
        this[PROCESS]();
      }
      [ADDFSENTRY](p) {
        const absolute = (0, normalize_windows_path_js_1.normalizeWindowsPath)(path_1.default.resolve(this.cwd, p));
        this[QUEUE].push(new PackJob(p, absolute));
        this[PROCESS]();
      }
      [STAT](job) {
        job.pending = true;
        this[JOBS] += 1;
        const stat = this.follow ? "stat" : "lstat";
        fs_1.default[stat](job.absolute, (er, stat2) => {
          job.pending = false;
          this[JOBS] -= 1;
          if (er) {
            this.emit("error", er);
          } else {
            this[ONSTAT](job, stat2);
          }
        });
      }
      [ONSTAT](job, stat) {
        this.statCache.set(job.absolute, stat);
        job.stat = stat;
        if (!this.filter(job.path, stat)) {
          job.ignore = true;
        } else if (stat.isFile() && stat.nlink > 1 && !this.linkCache.get(`${stat.dev}:${stat.ino}`) && !this.sync) {
          if (job === this[CURRENT]) {
            this[PROCESSJOB](job);
          } else {
            const key = `${stat.dev}:${stat.ino}`;
            const pending = this[PENDINGLINKS].get(key);
            if (pending)
              pending.push(job);
            else
              this[PENDINGLINKS].set(key, [job]);
            job.pendingLink = true;
            job.pending = true;
          }
        }
        this[PROCESS]();
      }
      [READDIR](job) {
        job.pending = true;
        this[JOBS] += 1;
        fs_1.default.readdir(job.absolute, (er, entries) => {
          job.pending = false;
          this[JOBS] -= 1;
          if (er) {
            return this.emit("error", er);
          }
          this[ONREADDIR](job, entries);
        });
      }
      [ONREADDIR](job, entries) {
        this.readdirCache.set(job.absolute, entries);
        job.readdir = entries;
        this[PROCESS]();
      }
      [PROCESS]() {
        if (this[PROCESSING]) {
          return;
        }
        this[PROCESSING] = true;
        for (let w = this[QUEUE].head; !!w && this[JOBS] < this.jobs; w = w.next) {
          this[PROCESSJOB](w.value);
          if (w.value.ignore) {
            const p = w.next;
            this[QUEUE].removeNode(w);
            w.next = p;
          }
        }
        this[PROCESSING] = false;
        if (this[ENDED] && this[QUEUE].length === 0 && this[JOBS] === 0) {
          if (this.zip) {
            this.zip.end(EOF);
          } else {
            super.write(EOF);
            super.end();
          }
        }
      }
      get [CURRENT]() {
        return this[QUEUE] && this[QUEUE].head && this[QUEUE].head.value;
      }
      [JOBDONE](job) {
        this[QUEUE].shift();
        this[JOBS] -= 1;
        const { stat } = job;
        if (stat && stat.isFile() && stat.nlink > 1) {
          const key = `${stat.dev}:${stat.ino}`;
          const pending = this[PENDINGLINKS].get(key);
          if (pending) {
            this[PENDINGLINKS].delete(key);
            for (const job2 of pending) {
              job2.pending = false;
              this[PROCESSJOB](job2);
            }
          }
        }
        this[PROCESS]();
      }
      [PROCESSJOB](job) {
        if (job.pending && job.pendingLink && job === this[CURRENT]) {
          job.pending = false;
          job.pendingLink = false;
        }
        if (job.pending) {
          return;
        }
        if (job.entry) {
          if (job === this[CURRENT] && !job.piped) {
            this[PIPE](job);
          }
          return;
        }
        if (!job.stat) {
          const sc = this.statCache.get(job.absolute);
          if (sc) {
            this[ONSTAT](job, sc);
          } else {
            this[STAT](job);
          }
        }
        if (!job.stat) {
          return;
        }
        if (job.ignore) {
          return;
        }
        if (!this.noDirRecurse && job.stat.isDirectory() && !job.readdir) {
          const rc = this.readdirCache.get(job.absolute);
          if (rc) {
            this[ONREADDIR](job, rc);
          } else {
            this[READDIR](job);
          }
          if (!job.readdir) {
            return;
          }
        }
        job.entry = this[ENTRY](job);
        if (!job.entry) {
          job.ignore = true;
          return;
        }
        if (job === this[CURRENT] && !job.piped) {
          this[PIPE](job);
        }
      }
      [ENTRYOPT](job) {
        return {
          onwarn: (code, msg, data) => this.warn(code, msg, data),
          noPax: this.noPax,
          cwd: this.cwd,
          absolute: job.absolute,
          preservePaths: this.preservePaths,
          maxReadSize: this.maxReadSize,
          strict: this.strict,
          portable: this.portable,
          linkCache: this.linkCache,
          statCache: this.statCache,
          noMtime: this.noMtime,
          mtime: this.mtime,
          prefix: this.prefix,
          onWriteEntry: this.onWriteEntry
        };
      }
      [ENTRY](job) {
        this[JOBS] += 1;
        try {
          const e = new this[WRITEENTRYCLASS](job.path, this[ENTRYOPT](job));
          return e.on("end", () => this[JOBDONE](job)).on("error", (er) => this.emit("error", er));
        } catch (er) {
          this.emit("error", er);
        }
      }
      [ONDRAIN]() {
        if (this[CURRENT] && this[CURRENT].entry) {
          this[CURRENT].entry.resume();
        }
      }
      // like .pipe() but using super, because our write() is special
      [PIPE](job) {
        job.piped = true;
        if (job.readdir) {
          job.readdir.forEach((entry) => {
            const p = job.path;
            const base = p === "./" ? "" : p.replace(/\/*$/, "/");
            this[ADDFSENTRY](base + entry);
          });
        }
        const source = job.entry;
        const zip = this.zip;
        if (!source)
          throw new Error("cannot pipe without source");
        if (zip) {
          source.on("data", (chunk) => {
            if (!zip.write(chunk)) {
              source.pause();
            }
          });
        } else {
          source.on("data", (chunk) => {
            if (!super.write(chunk)) {
              source.pause();
            }
          });
        }
      }
      pause() {
        if (this.zip) {
          this.zip.pause();
        }
        return super.pause();
      }
      warn(code, message, data = {}) {
        (0, warn_method_js_1.warnMethod)(this, code, message, data);
      }
    };
    exports2.Pack = Pack;
    var PackSync = class extends Pack {
      sync = true;
      constructor(opt) {
        super(opt);
        this[WRITEENTRYCLASS] = write_entry_js_1.WriteEntrySync;
      }
      // pause/resume are no-ops in sync streams.
      pause() {
      }
      resume() {
      }
      [STAT](job) {
        const stat = this.follow ? "statSync" : "lstatSync";
        this[ONSTAT](job, fs_1.default[stat](job.absolute));
      }
      [READDIR](job) {
        this[ONREADDIR](job, fs_1.default.readdirSync(job.absolute));
      }
      // gotta get it all in this tick
      [PIPE](job) {
        const source = job.entry;
        const zip = this.zip;
        if (job.readdir) {
          job.readdir.forEach((entry) => {
            const p = job.path;
            const base = p === "./" ? "" : p.replace(/\/*$/, "/");
            this[ADDFSENTRY](base + entry);
          });
        }
        if (!source)
          throw new Error("Cannot pipe without source");
        if (zip) {
          source.on("data", (chunk) => {
            zip.write(chunk);
          });
        } else {
          source.on("data", (chunk) => {
            super[WRITE](chunk);
          });
        }
      }
    };
    exports2.PackSync = PackSync;
  }
});

// ../node_modules/tar/dist/commonjs/create.js
var require_create = __commonJS({
  "../node_modules/tar/dist/commonjs/create.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.create = void 0;
    var fs_minipass_1 = require_commonjs2();
    var node_path_1 = __importDefault(require("node:path"));
    var list_js_1 = require_list();
    var make_command_js_1 = require_make_command();
    var pack_js_1 = require_pack();
    var createFileSync = (opt, files) => {
      const p = new pack_js_1.PackSync(opt);
      const stream = new fs_minipass_1.WriteStreamSync(opt.file, {
        mode: opt.mode || 438
      });
      p.pipe(stream);
      addFilesSync(p, files);
    };
    var createFile = (opt, files) => {
      const p = new pack_js_1.Pack(opt);
      const stream = new fs_minipass_1.WriteStream(opt.file, {
        mode: opt.mode || 438
      });
      p.pipe(stream);
      const promise = new Promise((res, rej) => {
        stream.on("error", rej);
        stream.on("close", res);
        p.on("error", rej);
      });
      addFilesAsync(p, files).catch((er) => p.emit("error", er));
      return promise;
    };
    var addFilesSync = (p, files) => {
      files.forEach((file) => {
        if (file.charAt(0) === "@") {
          (0, list_js_1.list)({
            file: node_path_1.default.resolve(p.cwd, file.slice(1)),
            sync: true,
            noResume: true,
            onReadEntry: (entry) => p.add(entry)
          });
        } else {
          p.add(file);
        }
      });
      p.end();
    };
    var addFilesAsync = async (p, files) => {
      for (const file of files) {
        if (file.charAt(0) === "@") {
          await (0, list_js_1.list)({
            file: node_path_1.default.resolve(String(p.cwd), file.slice(1)),
            noResume: true,
            onReadEntry: (entry) => {
              p.add(entry);
            }
          });
        } else {
          p.add(file);
        }
      }
      p.end();
    };
    var createSync = (opt, files) => {
      const p = new pack_js_1.PackSync(opt);
      addFilesSync(p, files);
      return p;
    };
    var createAsync = (opt, files) => {
      const p = new pack_js_1.Pack(opt);
      addFilesAsync(p, files).catch((er) => p.emit("error", er));
      return p;
    };
    exports2.create = (0, make_command_js_1.makeCommand)(createFileSync, createFile, createSync, createAsync, (_opt, files) => {
      if (!files?.length) {
        throw new TypeError("no paths specified to add to archive");
      }
    });
  }
});

// ../node_modules/tar/dist/commonjs/get-write-flag.js
var require_get_write_flag = __commonJS({
  "../node_modules/tar/dist/commonjs/get-write-flag.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.getWriteFlag = void 0;
    var fs_1 = __importDefault(require("fs"));
    var platform = process.env.__FAKE_PLATFORM__ || process.platform;
    var isWindows = platform === "win32";
    var { O_CREAT, O_NOFOLLOW, O_TRUNC, O_WRONLY } = fs_1.default.constants;
    var UV_FS_O_FILEMAP = Number(process.env.__FAKE_FS_O_FILENAME__) || fs_1.default.constants.UV_FS_O_FILEMAP || 0;
    var fMapEnabled = isWindows && !!UV_FS_O_FILEMAP;
    var fMapLimit = 512 * 1024;
    var fMapFlag = UV_FS_O_FILEMAP | O_TRUNC | O_CREAT | O_WRONLY;
    var noFollowFlag = !isWindows && typeof O_NOFOLLOW === "number" ? O_NOFOLLOW | O_TRUNC | O_CREAT | O_WRONLY : null;
    exports2.getWriteFlag = noFollowFlag !== null ? () => noFollowFlag : !fMapEnabled ? () => "w" : (size) => size < fMapLimit ? fMapFlag : "w";
  }
});

// ../node_modules/chownr/dist/commonjs/index.js
var require_commonjs6 = __commonJS({
  "../node_modules/chownr/dist/commonjs/index.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.chownrSync = exports2.chownr = void 0;
    var node_fs_1 = __importDefault(require("node:fs"));
    var node_path_1 = __importDefault(require("node:path"));
    var lchownSync = (path2, uid, gid) => {
      try {
        return node_fs_1.default.lchownSync(path2, uid, gid);
      } catch (er) {
        if (er?.code !== "ENOENT")
          throw er;
      }
    };
    var chown = (cpath, uid, gid, cb) => {
      node_fs_1.default.lchown(cpath, uid, gid, (er) => {
        cb(er && er?.code !== "ENOENT" ? er : null);
      });
    };
    var chownrKid = (p, child, uid, gid, cb) => {
      if (child.isDirectory()) {
        (0, exports2.chownr)(node_path_1.default.resolve(p, child.name), uid, gid, (er) => {
          if (er)
            return cb(er);
          const cpath = node_path_1.default.resolve(p, child.name);
          chown(cpath, uid, gid, cb);
        });
      } else {
        const cpath = node_path_1.default.resolve(p, child.name);
        chown(cpath, uid, gid, cb);
      }
    };
    var chownr = (p, uid, gid, cb) => {
      node_fs_1.default.readdir(p, { withFileTypes: true }, (er, children) => {
        if (er) {
          if (er.code === "ENOENT")
            return cb();
          else if (er.code !== "ENOTDIR" && er.code !== "ENOTSUP")
            return cb(er);
        }
        if (er || !children.length)
          return chown(p, uid, gid, cb);
        let len = children.length;
        let errState = null;
        const then = (er2) => {
          if (errState)
            return;
          if (er2)
            return cb(errState = er2);
          if (--len === 0)
            return chown(p, uid, gid, cb);
        };
        for (const child of children) {
          chownrKid(p, child, uid, gid, then);
        }
      });
    };
    exports2.chownr = chownr;
    var chownrKidSync = (p, child, uid, gid) => {
      if (child.isDirectory())
        (0, exports2.chownrSync)(node_path_1.default.resolve(p, child.name), uid, gid);
      lchownSync(node_path_1.default.resolve(p, child.name), uid, gid);
    };
    var chownrSync = (p, uid, gid) => {
      let children;
      try {
        children = node_fs_1.default.readdirSync(p, { withFileTypes: true });
      } catch (er) {
        const e = er;
        if (e?.code === "ENOENT")
          return;
        else if (e?.code === "ENOTDIR" || e?.code === "ENOTSUP")
          return lchownSync(p, uid, gid);
        else
          throw e;
      }
      for (const child of children) {
        chownrKidSync(p, child, uid, gid);
      }
      return lchownSync(p, uid, gid);
    };
    exports2.chownrSync = chownrSync;
  }
});

// ../node_modules/tar/dist/commonjs/cwd-error.js
var require_cwd_error = __commonJS({
  "../node_modules/tar/dist/commonjs/cwd-error.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.CwdError = void 0;
    var CwdError = class extends Error {
      path;
      code;
      syscall = "chdir";
      constructor(path2, code) {
        super(`${code}: Cannot cd into '${path2}'`);
        this.path = path2;
        this.code = code;
      }
      get name() {
        return "CwdError";
      }
    };
    exports2.CwdError = CwdError;
  }
});

// ../node_modules/tar/dist/commonjs/symlink-error.js
var require_symlink_error = __commonJS({
  "../node_modules/tar/dist/commonjs/symlink-error.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.SymlinkError = void 0;
    var SymlinkError = class extends Error {
      path;
      symlink;
      syscall = "symlink";
      code = "TAR_SYMLINK_ERROR";
      constructor(symlink, path2) {
        super("TAR_SYMLINK_ERROR: Cannot extract through symbolic link");
        this.symlink = symlink;
        this.path = path2;
      }
      get name() {
        return "SymlinkError";
      }
    };
    exports2.SymlinkError = SymlinkError;
  }
});

// ../node_modules/tar/dist/commonjs/mkdir.js
var require_mkdir = __commonJS({
  "../node_modules/tar/dist/commonjs/mkdir.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.mkdirSync = exports2.mkdir = void 0;
    var chownr_1 = require_commonjs6();
    var node_fs_1 = __importDefault(require("node:fs"));
    var promises_1 = __importDefault(require("node:fs/promises"));
    var node_path_1 = __importDefault(require("node:path"));
    var cwd_error_js_1 = require_cwd_error();
    var normalize_windows_path_js_1 = require_normalize_windows_path();
    var symlink_error_js_1 = require_symlink_error();
    var checkCwd = (dir, cb) => {
      node_fs_1.default.stat(dir, (er, st) => {
        if (er || !st.isDirectory()) {
          er = new cwd_error_js_1.CwdError(dir, er?.code || "ENOTDIR");
        }
        cb(er);
      });
    };
    var mkdir = (dir, opt, cb) => {
      dir = (0, normalize_windows_path_js_1.normalizeWindowsPath)(dir);
      const umask = opt.umask ?? 18;
      const mode = opt.mode | 448;
      const needChmod = (mode & umask) !== 0;
      const uid = opt.uid;
      const gid = opt.gid;
      const doChown = typeof uid === "number" && typeof gid === "number" && (uid !== opt.processUid || gid !== opt.processGid);
      const preserve = opt.preserve;
      const unlink = opt.unlink;
      const cwd = (0, normalize_windows_path_js_1.normalizeWindowsPath)(opt.cwd);
      const done = (er, created) => {
        if (er) {
          cb(er);
        } else {
          if (created && doChown) {
            (0, chownr_1.chownr)(created, uid, gid, (er2) => done(er2));
          } else if (needChmod) {
            node_fs_1.default.chmod(dir, mode, cb);
          } else {
            cb();
          }
        }
      };
      if (dir === cwd) {
        return checkCwd(dir, done);
      }
      if (preserve) {
        return promises_1.default.mkdir(dir, { mode, recursive: true }).then(
          (made) => done(null, made ?? void 0),
          // oh, ts
          done
        );
      }
      const sub = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.relative(cwd, dir));
      const parts = sub.split("/");
      mkdir_(cwd, parts, mode, unlink, cwd, void 0, done);
    };
    exports2.mkdir = mkdir;
    var mkdir_ = (base, parts, mode, unlink, cwd, created, cb) => {
      if (parts.length === 0) {
        return cb(null, created);
      }
      const p = parts.shift();
      const part = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.resolve(base + "/" + p));
      node_fs_1.default.mkdir(part, mode, onmkdir(part, parts, mode, unlink, cwd, created, cb));
    };
    var onmkdir = (part, parts, mode, unlink, cwd, created, cb) => (er) => {
      if (er) {
        node_fs_1.default.lstat(part, (statEr, st) => {
          if (statEr) {
            statEr.path = statEr.path && (0, normalize_windows_path_js_1.normalizeWindowsPath)(statEr.path);
            cb(statEr);
          } else if (st.isDirectory()) {
            mkdir_(part, parts, mode, unlink, cwd, created, cb);
          } else if (unlink) {
            node_fs_1.default.unlink(part, (er2) => {
              if (er2) {
                return cb(er2);
              }
              node_fs_1.default.mkdir(part, mode, onmkdir(part, parts, mode, unlink, cwd, created, cb));
            });
          } else if (st.isSymbolicLink()) {
            return cb(new symlink_error_js_1.SymlinkError(part, part + "/" + parts.join("/")));
          } else {
            cb(er);
          }
        });
      } else {
        created = created || part;
        mkdir_(part, parts, mode, unlink, cwd, created, cb);
      }
    };
    var checkCwdSync = (dir) => {
      let ok = false;
      let code;
      try {
        ok = node_fs_1.default.statSync(dir).isDirectory();
      } catch (er) {
        code = er?.code;
      } finally {
        if (!ok) {
          throw new cwd_error_js_1.CwdError(dir, code ?? "ENOTDIR");
        }
      }
    };
    var mkdirSync = (dir, opt) => {
      dir = (0, normalize_windows_path_js_1.normalizeWindowsPath)(dir);
      const umask = opt.umask ?? 18;
      const mode = opt.mode | 448;
      const needChmod = (mode & umask) !== 0;
      const uid = opt.uid;
      const gid = opt.gid;
      const doChown = typeof uid === "number" && typeof gid === "number" && (uid !== opt.processUid || gid !== opt.processGid);
      const preserve = opt.preserve;
      const unlink = opt.unlink;
      const cwd = (0, normalize_windows_path_js_1.normalizeWindowsPath)(opt.cwd);
      const done = (created2) => {
        if (created2 && doChown) {
          (0, chownr_1.chownrSync)(created2, uid, gid);
        }
        if (needChmod) {
          node_fs_1.default.chmodSync(dir, mode);
        }
      };
      if (dir === cwd) {
        checkCwdSync(cwd);
        return done();
      }
      if (preserve) {
        return done(node_fs_1.default.mkdirSync(dir, { mode, recursive: true }) ?? void 0);
      }
      const sub = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.relative(cwd, dir));
      const parts = sub.split("/");
      let created;
      for (let p = parts.shift(), part = cwd; p && (part += "/" + p); p = parts.shift()) {
        part = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.resolve(part));
        try {
          node_fs_1.default.mkdirSync(part, mode);
          created = created || part;
        } catch {
          const st = node_fs_1.default.lstatSync(part);
          if (st.isDirectory()) {
            continue;
          } else if (unlink) {
            node_fs_1.default.unlinkSync(part);
            node_fs_1.default.mkdirSync(part, mode);
            created = created || part;
            continue;
          } else if (st.isSymbolicLink()) {
            return new symlink_error_js_1.SymlinkError(part, part + "/" + parts.join("/"));
          }
        }
      }
      return done(created);
    };
    exports2.mkdirSync = mkdirSync;
  }
});

// ../node_modules/tar/dist/commonjs/normalize-unicode.js
var require_normalize_unicode = __commonJS({
  "../node_modules/tar/dist/commonjs/normalize-unicode.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.normalizeUnicode = void 0;
    var normalizeCache = /* @__PURE__ */ Object.create(null);
    var MAX = 1e4;
    var cache = /* @__PURE__ */ new Set();
    var normalizeUnicode = (s) => {
      if (!cache.has(s)) {
        normalizeCache[s] = s.normalize("NFD").toLocaleLowerCase("en").toLocaleUpperCase("en");
      } else {
        cache.delete(s);
      }
      cache.add(s);
      const ret = normalizeCache[s];
      let i = cache.size - MAX;
      if (i > MAX / 10) {
        for (const s2 of cache) {
          cache.delete(s2);
          delete normalizeCache[s2];
          if (--i <= 0)
            break;
        }
      }
      return ret;
    };
    exports2.normalizeUnicode = normalizeUnicode;
  }
});

// ../node_modules/tar/dist/commonjs/path-reservations.js
var require_path_reservations = __commonJS({
  "../node_modules/tar/dist/commonjs/path-reservations.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.PathReservations = void 0;
    var node_path_1 = require("node:path");
    var normalize_unicode_js_1 = require_normalize_unicode();
    var strip_trailing_slashes_js_1 = require_strip_trailing_slashes();
    var platform = process.env.TESTING_TAR_FAKE_PLATFORM || process.platform;
    var isWindows = platform === "win32";
    var getDirs = (path2) => {
      const dirs = path2.split("/").slice(0, -1).reduce((set, path3) => {
        const s = set.at(-1);
        if (s !== void 0) {
          path3 = (0, node_path_1.join)(s, path3);
        }
        set.push(path3 || "/");
        return set;
      }, []);
      return dirs;
    };
    var PathReservations = class {
      // path => [function or Set]
      // A Set object means a directory reservation
      // A fn is a direct reservation on that path
      #queues = /* @__PURE__ */ new Map();
      // fn => {paths:[path,...], dirs:[path, ...]}
      #reservations = /* @__PURE__ */ new Map();
      // functions currently running
      #running = /* @__PURE__ */ new Set();
      reserve(paths, fn) {
        paths = isWindows ? ["win32 parallelization disabled"] : paths.map((p) => {
          return (0, strip_trailing_slashes_js_1.stripTrailingSlashes)((0, node_path_1.join)((0, normalize_unicode_js_1.normalizeUnicode)(p)));
        });
        const dirs = new Set(paths.map((path2) => getDirs(path2)).reduce((a, b) => a.concat(b)));
        this.#reservations.set(fn, { dirs, paths });
        for (const p of paths) {
          const q = this.#queues.get(p);
          if (!q) {
            this.#queues.set(p, [fn]);
          } else {
            q.push(fn);
          }
        }
        for (const dir of dirs) {
          const q = this.#queues.get(dir);
          if (!q) {
            this.#queues.set(dir, [/* @__PURE__ */ new Set([fn])]);
          } else {
            const l = q.at(-1);
            if (l instanceof Set) {
              l.add(fn);
            } else {
              q.push(/* @__PURE__ */ new Set([fn]));
            }
          }
        }
        return this.#run(fn);
      }
      // return the queues for each path the function cares about
      // fn => {paths, dirs}
      #getQueues(fn) {
        const res = this.#reservations.get(fn);
        if (!res) {
          throw new Error("function does not have any path reservations");
        }
        return {
          paths: res.paths.map((path2) => this.#queues.get(path2)),
          dirs: [...res.dirs].map((path2) => this.#queues.get(path2))
        };
      }
      // check if fn is first in line for all its paths, and is
      // included in the first set for all its dir queues
      check(fn) {
        const { paths, dirs } = this.#getQueues(fn);
        return paths.every((q) => q && q[0] === fn) && dirs.every((q) => q && q[0] instanceof Set && q[0].has(fn));
      }
      // run the function if it's first in line and not already running
      #run(fn) {
        if (this.#running.has(fn) || !this.check(fn)) {
          return false;
        }
        this.#running.add(fn);
        fn(() => this.#clear(fn));
        return true;
      }
      #clear(fn) {
        if (!this.#running.has(fn)) {
          return false;
        }
        const res = this.#reservations.get(fn);
        if (!res) {
          throw new Error("invalid reservation");
        }
        const { paths, dirs } = res;
        const next = /* @__PURE__ */ new Set();
        for (const path2 of paths) {
          const q = this.#queues.get(path2);
          if (!q || q?.[0] !== fn) {
            continue;
          }
          const q0 = q[1];
          if (!q0) {
            this.#queues.delete(path2);
            continue;
          }
          q.shift();
          if (typeof q0 === "function") {
            next.add(q0);
          } else {
            for (const f of q0) {
              next.add(f);
            }
          }
        }
        for (const dir of dirs) {
          const q = this.#queues.get(dir);
          const q0 = q?.[0];
          if (!q || !(q0 instanceof Set))
            continue;
          if (q0.size === 1 && q.length === 1) {
            this.#queues.delete(dir);
            continue;
          } else if (q0.size === 1) {
            q.shift();
            const n = q[0];
            if (typeof n === "function") {
              next.add(n);
            }
          } else {
            q0.delete(fn);
          }
        }
        this.#running.delete(fn);
        next.forEach((fn2) => this.#run(fn2));
        return true;
      }
    };
    exports2.PathReservations = PathReservations;
  }
});

// ../node_modules/tar/dist/commonjs/process-umask.js
var require_process_umask = __commonJS({
  "../node_modules/tar/dist/commonjs/process-umask.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.umask = void 0;
    var umask = () => process.umask();
    exports2.umask = umask;
  }
});

// ../node_modules/tar/dist/commonjs/unpack.js
var require_unpack = __commonJS({
  "../node_modules/tar/dist/commonjs/unpack.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.UnpackSync = exports2.Unpack = void 0;
    var fsm = __importStar(require_commonjs2());
    var node_assert_1 = __importDefault(require("node:assert"));
    var node_crypto_1 = require("node:crypto");
    var node_fs_1 = __importDefault(require("node:fs"));
    var node_path_1 = __importDefault(require("node:path"));
    var get_write_flag_js_1 = require_get_write_flag();
    var mkdir_js_1 = require_mkdir();
    var normalize_windows_path_js_1 = require_normalize_windows_path();
    var parse_js_1 = require_parse();
    var strip_absolute_path_js_1 = require_strip_absolute_path();
    var wc = __importStar(require_winchars());
    var path_reservations_js_1 = require_path_reservations();
    var symlink_error_js_1 = require_symlink_error();
    var process_umask_js_1 = require_process_umask();
    var ONENTRY = /* @__PURE__ */ Symbol("onEntry");
    var CHECKFS = /* @__PURE__ */ Symbol("checkFs");
    var CHECKFS2 = /* @__PURE__ */ Symbol("checkFs2");
    var ISREUSABLE = /* @__PURE__ */ Symbol("isReusable");
    var MAKEFS = /* @__PURE__ */ Symbol("makeFs");
    var FILE = /* @__PURE__ */ Symbol("file");
    var DIRECTORY = /* @__PURE__ */ Symbol("directory");
    var LINK = /* @__PURE__ */ Symbol("link");
    var SYMLINK = /* @__PURE__ */ Symbol("symlink");
    var HARDLINK = /* @__PURE__ */ Symbol("hardlink");
    var ENSURE_NO_SYMLINK = /* @__PURE__ */ Symbol("ensureNoSymlink");
    var UNSUPPORTED = /* @__PURE__ */ Symbol("unsupported");
    var CHECKPATH = /* @__PURE__ */ Symbol("checkPath");
    var STRIPABSOLUTEPATH = /* @__PURE__ */ Symbol("stripAbsolutePath");
    var MKDIR = /* @__PURE__ */ Symbol("mkdir");
    var ONERROR = /* @__PURE__ */ Symbol("onError");
    var PENDING = /* @__PURE__ */ Symbol("pending");
    var PEND = /* @__PURE__ */ Symbol("pend");
    var UNPEND = /* @__PURE__ */ Symbol("unpend");
    var ENDED = /* @__PURE__ */ Symbol("ended");
    var MAYBECLOSE = /* @__PURE__ */ Symbol("maybeClose");
    var SKIP = /* @__PURE__ */ Symbol("skip");
    var DOCHOWN = /* @__PURE__ */ Symbol("doChown");
    var UID = /* @__PURE__ */ Symbol("uid");
    var GID = /* @__PURE__ */ Symbol("gid");
    var CHECKED_CWD = /* @__PURE__ */ Symbol("checkedCwd");
    var platform = process.env.TESTING_TAR_FAKE_PLATFORM || process.platform;
    var isWindows = platform === "win32";
    var DEFAULT_MAX_DEPTH = 1024;
    var unlinkFile = (path2, cb) => {
      if (!isWindows) {
        return node_fs_1.default.unlink(path2, cb);
      }
      const name = path2 + ".DELETE." + (0, node_crypto_1.randomBytes)(16).toString("hex");
      node_fs_1.default.rename(path2, name, (er) => {
        if (er) {
          return cb(er);
        }
        node_fs_1.default.unlink(name, cb);
      });
    };
    var unlinkFileSync = (path2) => {
      if (!isWindows) {
        return node_fs_1.default.unlinkSync(path2);
      }
      const name = path2 + ".DELETE." + (0, node_crypto_1.randomBytes)(16).toString("hex");
      node_fs_1.default.renameSync(path2, name);
      node_fs_1.default.unlinkSync(name);
    };
    var uint32 = (a, b, c) => a !== void 0 && a === a >>> 0 ? a : b !== void 0 && b === b >>> 0 ? b : c;
    var Unpack = class extends parse_js_1.Parser {
      [ENDED] = false;
      [CHECKED_CWD] = false;
      [PENDING] = 0;
      reservations = new path_reservations_js_1.PathReservations();
      transform;
      writable = true;
      readable = false;
      uid;
      gid;
      setOwner;
      preserveOwner;
      processGid;
      processUid;
      maxDepth;
      forceChown;
      win32;
      newer;
      keep;
      noMtime;
      preservePaths;
      unlink;
      cwd;
      strip;
      processUmask;
      umask;
      dmode;
      fmode;
      chmod;
      constructor(opt = {}) {
        opt.ondone = () => {
          this[ENDED] = true;
          this[MAYBECLOSE]();
        };
        super(opt);
        this.transform = opt.transform;
        this.chmod = !!opt.chmod;
        if (typeof opt.uid === "number" || typeof opt.gid === "number") {
          if (typeof opt.uid !== "number" || typeof opt.gid !== "number") {
            throw new TypeError("cannot set owner without number uid and gid");
          }
          if (opt.preserveOwner) {
            throw new TypeError("cannot preserve owner in archive and also set owner explicitly");
          }
          this.uid = opt.uid;
          this.gid = opt.gid;
          this.setOwner = true;
        } else {
          this.uid = void 0;
          this.gid = void 0;
          this.setOwner = false;
        }
        this.preserveOwner = opt.preserveOwner === void 0 && typeof opt.uid !== "number" ? !!(process.getuid?.() === 0) : !!opt.preserveOwner;
        this.processUid = (this.preserveOwner || this.setOwner) && process.getuid ? process.getuid() : void 0;
        this.processGid = (this.preserveOwner || this.setOwner) && process.getgid ? process.getgid() : void 0;
        this.maxDepth = typeof opt.maxDepth === "number" ? opt.maxDepth : DEFAULT_MAX_DEPTH;
        this.forceChown = opt.forceChown === true;
        this.win32 = !!opt.win32 || isWindows;
        this.newer = !!opt.newer;
        this.keep = !!opt.keep;
        this.noMtime = !!opt.noMtime;
        this.preservePaths = !!opt.preservePaths;
        this.unlink = !!opt.unlink;
        this.cwd = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.resolve(opt.cwd || process.cwd()));
        this.strip = Number(opt.strip) || 0;
        this.processUmask = !this.chmod ? 0 : typeof opt.processUmask === "number" ? opt.processUmask : (0, process_umask_js_1.umask)();
        this.umask = typeof opt.umask === "number" ? opt.umask : this.processUmask;
        this.dmode = opt.dmode || 511 & ~this.umask;
        this.fmode = opt.fmode || 438 & ~this.umask;
        this.on("entry", (entry) => this[ONENTRY](entry));
      }
      // a bad or damaged archive is a warning for Parser, but an error
      // when extracting.  Mark those errors as unrecoverable, because
      // the Unpack contract cannot be met.
      warn(code, msg, data = {}) {
        if (code === "TAR_BAD_ARCHIVE" || code === "TAR_ABORT") {
          data.recoverable = false;
        }
        return super.warn(code, msg, data);
      }
      [MAYBECLOSE]() {
        if (this[ENDED] && this[PENDING] === 0) {
          this.emit("prefinish");
          this.emit("finish");
          this.emit("end");
        }
      }
      // return false if we need to skip this file
      // return true if the field was successfully sanitized
      [STRIPABSOLUTEPATH](entry, field) {
        const p = entry[field];
        const { type } = entry;
        if (!p || this.preservePaths)
          return true;
        const [root, stripped] = (0, strip_absolute_path_js_1.stripAbsolutePath)(p);
        const parts = stripped.replaceAll(/\\/g, "/").split("/");
        if (parts.includes("..") || /* c8 ignore next */
        isWindows && /^[a-z]:\.\.$/i.test(parts[0] ?? "")) {
          if (field === "path" || type === "Link") {
            this.warn("TAR_ENTRY_ERROR", `${field} contains '..'`, {
              entry,
              [field]: p
            });
            return false;
          }
          const entryDir = node_path_1.default.posix.dirname(entry.path);
          const resolved = node_path_1.default.posix.normalize(node_path_1.default.posix.join(entryDir, parts.join("/")));
          if (resolved.startsWith("../") || resolved === "..") {
            this.warn("TAR_ENTRY_ERROR", `${field} escapes extraction directory`, {
              entry,
              [field]: p
            });
            return false;
          }
        }
        if (root) {
          entry[field] = String(stripped);
          this.warn("TAR_ENTRY_INFO", `stripping ${root} from absolute ${field}`, {
            entry,
            [field]: p
          });
        }
        return true;
      }
      // no IO, just string checking for absolute indicators
      [CHECKPATH](entry) {
        const p = (0, normalize_windows_path_js_1.normalizeWindowsPath)(entry.path);
        const parts = p.split("/");
        if (this.strip) {
          if (parts.length < this.strip) {
            return false;
          }
          if (entry.type === "Link") {
            const linkparts = (0, normalize_windows_path_js_1.normalizeWindowsPath)(String(entry.linkpath)).split("/");
            if (linkparts.length >= this.strip) {
              entry.linkpath = linkparts.slice(this.strip).join("/");
            } else {
              return false;
            }
          }
          parts.splice(0, this.strip);
          entry.path = parts.join("/");
        }
        if (isFinite(this.maxDepth) && parts.length > this.maxDepth) {
          this.warn("TAR_ENTRY_ERROR", "path excessively deep", {
            entry,
            path: p,
            depth: parts.length,
            maxDepth: this.maxDepth
          });
          return false;
        }
        if (!this[STRIPABSOLUTEPATH](entry, "path") || !this[STRIPABSOLUTEPATH](entry, "linkpath")) {
          return false;
        }
        entry.absolute = node_path_1.default.isAbsolute(entry.path) ? (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.resolve(entry.path)) : (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.resolve(this.cwd, entry.path));
        if (!this.preservePaths && typeof entry.absolute === "string" && entry.absolute.indexOf(this.cwd + "/") !== 0 && entry.absolute !== this.cwd) {
          this.warn("TAR_ENTRY_ERROR", "path escaped extraction target", {
            entry,
            path: (0, normalize_windows_path_js_1.normalizeWindowsPath)(entry.path),
            resolvedPath: entry.absolute,
            cwd: this.cwd
          });
          return false;
        }
        if (entry.absolute === this.cwd && entry.type !== "Directory" && entry.type !== "GNUDumpDir") {
          return false;
        }
        if (this.win32) {
          const { root: aRoot } = node_path_1.default.win32.parse(String(entry.absolute));
          entry.absolute = aRoot + wc.encode(String(entry.absolute).slice(aRoot.length));
          const { root: pRoot } = node_path_1.default.win32.parse(entry.path);
          entry.path = pRoot + wc.encode(entry.path.slice(pRoot.length));
        }
        return true;
      }
      [ONENTRY](entry) {
        if (!this[CHECKPATH](entry)) {
          return entry.resume();
        }
        node_assert_1.default.equal(typeof entry.absolute, "string");
        switch (entry.type) {
          case "Directory":
          case "GNUDumpDir":
            if (entry.mode) {
              entry.mode = entry.mode | 448;
            }
          // eslint-disable-next-line no-fallthrough
          case "File":
          case "OldFile":
          case "ContiguousFile":
          case "Link":
          case "SymbolicLink":
            return this[CHECKFS](entry);
          case "CharacterDevice":
          case "BlockDevice":
          case "FIFO":
          default:
            return this[UNSUPPORTED](entry);
        }
      }
      [ONERROR](er, entry) {
        if (er.name === "CwdError") {
          this.emit("error", er);
        } else {
          this.warn("TAR_ENTRY_ERROR", er, { entry });
          this[UNPEND]();
          entry.resume();
        }
      }
      [MKDIR](dir, mode, cb) {
        void (0, mkdir_js_1.mkdir)((0, normalize_windows_path_js_1.normalizeWindowsPath)(dir), {
          uid: this.uid,
          gid: this.gid,
          processUid: this.processUid,
          processGid: this.processGid,
          umask: this.processUmask,
          preserve: this.preservePaths,
          unlink: this.unlink,
          cwd: this.cwd,
          mode
        }, cb);
      }
      [DOCHOWN](entry) {
        return this.forceChown || this.preserveOwner && (typeof entry.uid === "number" && entry.uid !== this.processUid || typeof entry.gid === "number" && entry.gid !== this.processGid) || typeof this.uid === "number" && this.uid !== this.processUid || typeof this.gid === "number" && this.gid !== this.processGid;
      }
      [UID](entry) {
        return uint32(this.uid, entry.uid, this.processUid);
      }
      [GID](entry) {
        return uint32(this.gid, entry.gid, this.processGid);
      }
      [FILE](entry, fullyDone) {
        const mode = typeof entry.mode === "number" ? entry.mode & 4095 : this.fmode;
        const stream = new fsm.WriteStream(String(entry.absolute), {
          // slight lie, but it can be numeric flags
          flags: (0, get_write_flag_js_1.getWriteFlag)(entry.size),
          mode,
          autoClose: false
        });
        stream.on("error", (er) => {
          if (stream.fd) {
            node_fs_1.default.close(stream.fd, () => {
            });
          }
          stream.write = () => true;
          this[ONERROR](er, entry);
          fullyDone();
        });
        let actions = 1;
        const done = (er) => {
          if (er) {
            if (stream.fd) {
              node_fs_1.default.close(stream.fd, () => {
              });
            }
            this[ONERROR](er, entry);
            fullyDone();
            return;
          }
          if (--actions === 0) {
            if (stream.fd !== void 0) {
              node_fs_1.default.close(stream.fd, (er2) => {
                if (er2) {
                  this[ONERROR](er2, entry);
                } else {
                  this[UNPEND]();
                }
                fullyDone();
              });
            }
          }
        };
        stream.on("finish", () => {
          const abs = String(entry.absolute);
          const fd = stream.fd;
          if (typeof fd === "number" && entry.mtime && !this.noMtime) {
            actions++;
            const atime = entry.atime || /* @__PURE__ */ new Date();
            const mtime = entry.mtime;
            node_fs_1.default.futimes(fd, atime, mtime, (er) => er ? node_fs_1.default.utimes(abs, atime, mtime, (er2) => done(er2 && er)) : done());
          }
          if (typeof fd === "number" && this[DOCHOWN](entry)) {
            actions++;
            const uid = this[UID](entry);
            const gid = this[GID](entry);
            if (typeof uid === "number" && typeof gid === "number") {
              node_fs_1.default.fchown(fd, uid, gid, (er) => er ? node_fs_1.default.chown(abs, uid, gid, (er2) => done(er2 && er)) : done());
            }
          }
          done();
        });
        const tx = this.transform ? this.transform(entry) || entry : entry;
        if (tx !== entry) {
          tx.on("error", (er) => {
            this[ONERROR](er, entry);
            fullyDone();
          });
          entry.pipe(tx);
        }
        tx.pipe(stream);
      }
      [DIRECTORY](entry, fullyDone) {
        const mode = typeof entry.mode === "number" ? entry.mode & 4095 : this.dmode;
        this[MKDIR](String(entry.absolute), mode, (er) => {
          if (er) {
            this[ONERROR](er, entry);
            fullyDone();
            return;
          }
          let actions = 1;
          const done = () => {
            if (--actions === 0) {
              fullyDone();
              this[UNPEND]();
              entry.resume();
            }
          };
          if (entry.mtime && !this.noMtime) {
            actions++;
            node_fs_1.default.utimes(String(entry.absolute), entry.atime || /* @__PURE__ */ new Date(), entry.mtime, done);
          }
          if (this[DOCHOWN](entry)) {
            actions++;
            node_fs_1.default.chown(String(entry.absolute), Number(this[UID](entry)), Number(this[GID](entry)), done);
          }
          done();
        });
      }
      [UNSUPPORTED](entry) {
        entry.unsupported = true;
        this.warn("TAR_ENTRY_UNSUPPORTED", `unsupported entry type: ${entry.type}`, { entry });
        entry.resume();
      }
      [SYMLINK](entry, done) {
        const parts = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.relative(this.cwd, node_path_1.default.resolve(node_path_1.default.dirname(String(entry.absolute)), String(entry.linkpath)))).split("/");
        this[ENSURE_NO_SYMLINK](entry, this.cwd, parts, () => this[LINK](entry, String(entry.linkpath), "symlink", done), (er) => {
          this[ONERROR](er, entry);
          done();
        });
      }
      [HARDLINK](entry, done) {
        const linkpath = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.resolve(this.cwd, String(entry.linkpath)));
        const parts = (0, normalize_windows_path_js_1.normalizeWindowsPath)(String(entry.linkpath)).split("/");
        this[ENSURE_NO_SYMLINK](entry, this.cwd, parts, () => this[LINK](entry, linkpath, "link", done), (er) => {
          this[ONERROR](er, entry);
          done();
        });
      }
      [ENSURE_NO_SYMLINK](entry, cwd, parts, done, onError) {
        const p = parts.shift();
        if (this.preservePaths || p === void 0)
          return done();
        const t = node_path_1.default.resolve(cwd, p);
        node_fs_1.default.lstat(t, (er, st) => {
          if (er)
            return done();
          if (st?.isSymbolicLink()) {
            return onError(new symlink_error_js_1.SymlinkError(t, node_path_1.default.resolve(t, parts.join("/"))));
          }
          this[ENSURE_NO_SYMLINK](entry, t, parts, done, onError);
        });
      }
      [PEND]() {
        this[PENDING]++;
      }
      [UNPEND]() {
        this[PENDING]--;
        this[MAYBECLOSE]();
      }
      [SKIP](entry) {
        this[UNPEND]();
        entry.resume();
      }
      // Check if we can reuse an existing filesystem entry safely and
      // overwrite it, rather than unlinking and recreating
      // Windows doesn't report a useful nlink, so we just never reuse entries
      [ISREUSABLE](entry, st) {
        return entry.type === "File" && !this.unlink && st.isFile() && st.nlink <= 1 && !isWindows;
      }
      // check if a thing is there, and if so, try to clobber it
      [CHECKFS](entry) {
        this[PEND]();
        const paths = [entry.path];
        if (entry.linkpath) {
          paths.push(entry.linkpath);
        }
        this.reservations.reserve(paths, (done) => this[CHECKFS2](entry, done));
      }
      [CHECKFS2](entry, fullyDone) {
        const done = (er) => {
          fullyDone(er);
        };
        const checkCwd = () => {
          this[MKDIR](this.cwd, this.dmode, (er) => {
            if (er) {
              this[ONERROR](er, entry);
              done();
              return;
            }
            this[CHECKED_CWD] = true;
            start();
          });
        };
        const start = () => {
          if (entry.absolute !== this.cwd) {
            const parent = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.dirname(String(entry.absolute)));
            if (parent !== this.cwd) {
              return this[MKDIR](parent, this.dmode, (er) => {
                if (er) {
                  this[ONERROR](er, entry);
                  done();
                  return;
                }
                afterMakeParent();
              });
            }
          }
          afterMakeParent();
        };
        const afterMakeParent = () => {
          node_fs_1.default.lstat(String(entry.absolute), (lstatEr, st) => {
            if (st && (this.keep || /* c8 ignore next */
            this.newer && st.mtime > (entry.mtime ?? st.mtime))) {
              this[SKIP](entry);
              done();
              return;
            }
            if (lstatEr || this[ISREUSABLE](entry, st)) {
              return this[MAKEFS](null, entry, done);
            }
            if (st.isDirectory()) {
              if (entry.type === "Directory") {
                const needChmod = this.chmod && entry.mode && (st.mode & 4095) !== entry.mode;
                const afterChmod = (er) => this[MAKEFS](er ?? null, entry, done);
                if (!needChmod) {
                  return afterChmod();
                }
                return node_fs_1.default.chmod(String(entry.absolute), Number(entry.mode), afterChmod);
              }
              if (entry.absolute !== this.cwd) {
                return node_fs_1.default.rmdir(String(entry.absolute), (er) => this[MAKEFS](er ?? null, entry, done));
              }
            }
            if (entry.absolute === this.cwd) {
              return this[MAKEFS](null, entry, done);
            }
            unlinkFile(String(entry.absolute), (er) => this[MAKEFS](er ?? null, entry, done));
          });
        };
        if (this[CHECKED_CWD]) {
          start();
        } else {
          checkCwd();
        }
      }
      [MAKEFS](er, entry, done) {
        if (er) {
          this[ONERROR](er, entry);
          done();
          return;
        }
        switch (entry.type) {
          case "File":
          case "OldFile":
          case "ContiguousFile":
            return this[FILE](entry, done);
          case "Link":
            return this[HARDLINK](entry, done);
          case "SymbolicLink":
            return this[SYMLINK](entry, done);
          case "Directory":
          case "GNUDumpDir":
            return this[DIRECTORY](entry, done);
        }
      }
      [LINK](entry, linkpath, link, done) {
        node_fs_1.default[link](linkpath, String(entry.absolute), (er) => {
          if (er) {
            this[ONERROR](er, entry);
          } else {
            this[UNPEND]();
            entry.resume();
          }
          done();
        });
      }
    };
    exports2.Unpack = Unpack;
    var callSync = (fn) => {
      try {
        return [null, fn()];
      } catch (er) {
        return [er, null];
      }
    };
    var UnpackSync = class extends Unpack {
      sync = true;
      [MAKEFS](er, entry) {
        return super[MAKEFS](er, entry, () => {
        });
      }
      [CHECKFS](entry) {
        if (!this[CHECKED_CWD]) {
          const er2 = this[MKDIR](this.cwd, this.dmode);
          if (er2) {
            return this[ONERROR](er2, entry);
          }
          this[CHECKED_CWD] = true;
        }
        if (entry.absolute !== this.cwd) {
          const parent = (0, normalize_windows_path_js_1.normalizeWindowsPath)(node_path_1.default.dirname(String(entry.absolute)));
          if (parent !== this.cwd) {
            const mkParent = this[MKDIR](parent, this.dmode);
            if (mkParent) {
              return this[ONERROR](mkParent, entry);
            }
          }
        }
        const [lstatEr, st] = callSync(() => node_fs_1.default.lstatSync(String(entry.absolute)));
        if (st && (this.keep || /* c8 ignore next */
        this.newer && st.mtime > (entry.mtime ?? st.mtime))) {
          return this[SKIP](entry);
        }
        if (lstatEr || this[ISREUSABLE](entry, st)) {
          return this[MAKEFS](null, entry);
        }
        if (st.isDirectory()) {
          if (entry.type === "Directory") {
            const needChmod = this.chmod && entry.mode && (st.mode & 4095) !== entry.mode;
            const [er3] = needChmod ? callSync(() => {
              node_fs_1.default.chmodSync(String(entry.absolute), Number(entry.mode));
            }) : [];
            return this[MAKEFS](er3, entry);
          }
          const [er2] = callSync(() => node_fs_1.default.rmdirSync(String(entry.absolute)));
          this[MAKEFS](er2, entry);
        }
        const [er] = entry.absolute === this.cwd ? [] : callSync(() => unlinkFileSync(String(entry.absolute)));
        this[MAKEFS](er, entry);
      }
      [FILE](entry, done) {
        const mode = typeof entry.mode === "number" ? entry.mode & 4095 : this.fmode;
        const oner = (er) => {
          let closeError;
          try {
            node_fs_1.default.closeSync(fd);
          } catch (e) {
            closeError = e;
          }
          if (er || closeError) {
            this[ONERROR](er || closeError, entry);
          }
          done();
        };
        let fd;
        try {
          fd = node_fs_1.default.openSync(String(entry.absolute), (0, get_write_flag_js_1.getWriteFlag)(entry.size), mode);
        } catch (er) {
          return oner(er);
        }
        const tx = this.transform ? this.transform(entry) || entry : entry;
        if (tx !== entry) {
          tx.on("error", (er) => this[ONERROR](er, entry));
          entry.pipe(tx);
        }
        tx.on("data", (chunk) => {
          try {
            node_fs_1.default.writeSync(fd, chunk, 0, chunk.length);
          } catch (er) {
            oner(er);
          }
        });
        tx.on("end", () => {
          let er = null;
          if (entry.mtime && !this.noMtime) {
            const atime = entry.atime || /* @__PURE__ */ new Date();
            const mtime = entry.mtime;
            try {
              node_fs_1.default.futimesSync(fd, atime, mtime);
            } catch (futimeser) {
              try {
                node_fs_1.default.utimesSync(String(entry.absolute), atime, mtime);
              } catch {
                er = futimeser;
              }
            }
          }
          if (this[DOCHOWN](entry)) {
            const uid = this[UID](entry);
            const gid = this[GID](entry);
            try {
              node_fs_1.default.fchownSync(fd, Number(uid), Number(gid));
            } catch (fchowner) {
              try {
                node_fs_1.default.chownSync(String(entry.absolute), Number(uid), Number(gid));
              } catch {
                er = er || fchowner;
              }
            }
          }
          oner(er);
        });
      }
      [DIRECTORY](entry, done) {
        const mode = typeof entry.mode === "number" ? entry.mode & 4095 : this.dmode;
        const er = this[MKDIR](String(entry.absolute), mode);
        if (er) {
          this[ONERROR](er, entry);
          done();
          return;
        }
        if (entry.mtime && !this.noMtime) {
          try {
            node_fs_1.default.utimesSync(String(entry.absolute), entry.atime || /* @__PURE__ */ new Date(), entry.mtime);
          } catch {
          }
        }
        if (this[DOCHOWN](entry)) {
          try {
            node_fs_1.default.chownSync(String(entry.absolute), Number(this[UID](entry)), Number(this[GID](entry)));
          } catch {
          }
        }
        done();
        entry.resume();
      }
      [MKDIR](dir, mode) {
        try {
          return (0, mkdir_js_1.mkdirSync)((0, normalize_windows_path_js_1.normalizeWindowsPath)(dir), {
            uid: this.uid,
            gid: this.gid,
            processUid: this.processUid,
            processGid: this.processGid,
            umask: this.processUmask,
            preserve: this.preservePaths,
            unlink: this.unlink,
            cwd: this.cwd,
            mode
          });
        } catch (er) {
          return er;
        }
      }
      [ENSURE_NO_SYMLINK](_entry, cwd, parts, done, onError) {
        if (this.preservePaths || parts.length === 0)
          return done();
        let t = cwd;
        for (const p of parts) {
          t = node_path_1.default.resolve(t, p);
          const [er, st] = callSync(() => node_fs_1.default.lstatSync(t));
          if (er)
            return done();
          if (st.isSymbolicLink()) {
            return onError(new symlink_error_js_1.SymlinkError(t, node_path_1.default.resolve(cwd, parts.join("/"))));
          }
        }
        done();
      }
      [LINK](entry, linkpath, link, done) {
        const linkSync = `${link}Sync`;
        try {
          node_fs_1.default[linkSync](linkpath, String(entry.absolute));
          done();
          entry.resume();
        } catch (er) {
          return this[ONERROR](er, entry);
        }
      }
    };
    exports2.UnpackSync = UnpackSync;
  }
});

// ../node_modules/tar/dist/commonjs/extract.js
var require_extract = __commonJS({
  "../node_modules/tar/dist/commonjs/extract.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.extract = void 0;
    var fsm = __importStar(require_commonjs2());
    var node_fs_1 = __importDefault(require("node:fs"));
    var list_js_1 = require_list();
    var make_command_js_1 = require_make_command();
    var unpack_js_1 = require_unpack();
    var extractFileSync = (opt) => {
      const u = new unpack_js_1.UnpackSync(opt);
      const file = opt.file;
      const stat = node_fs_1.default.statSync(file);
      const readSize = opt.maxReadSize || 16 * 1024 * 1024;
      const stream = new fsm.ReadStreamSync(file, {
        readSize,
        size: stat.size
      });
      stream.pipe(u);
    };
    var extractFile = (opt, _) => {
      const u = new unpack_js_1.Unpack(opt);
      const readSize = opt.maxReadSize || 16 * 1024 * 1024;
      const file = opt.file;
      const p = new Promise((resolve, reject) => {
        u.on("error", reject);
        u.on("close", resolve);
        node_fs_1.default.stat(file, (er, stat) => {
          if (er) {
            reject(er);
          } else {
            const stream = new fsm.ReadStream(file, {
              readSize,
              size: stat.size
            });
            stream.on("error", reject);
            stream.pipe(u);
          }
        });
      });
      return p;
    };
    exports2.extract = (0, make_command_js_1.makeCommand)(extractFileSync, extractFile, (opt) => new unpack_js_1.UnpackSync(opt), (opt) => new unpack_js_1.Unpack(opt), (opt, files) => {
      if (files?.length)
        (0, list_js_1.filesFilter)(opt, files);
    });
  }
});

// ../node_modules/tar/dist/commonjs/replace.js
var require_replace = __commonJS({
  "../node_modules/tar/dist/commonjs/replace.js"(exports2) {
    "use strict";
    var __importDefault = exports2 && exports2.__importDefault || function(mod) {
      return mod && mod.__esModule ? mod : { "default": mod };
    };
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.replace = void 0;
    var fs_minipass_1 = require_commonjs2();
    var node_fs_1 = __importDefault(require("node:fs"));
    var node_path_1 = __importDefault(require("node:path"));
    var header_js_1 = require_header();
    var list_js_1 = require_list();
    var make_command_js_1 = require_make_command();
    var options_js_1 = require_options();
    var pack_js_1 = require_pack();
    var replaceSync = (opt, files) => {
      const p = new pack_js_1.PackSync(opt);
      let threw = true;
      let fd;
      let position;
      try {
        try {
          fd = node_fs_1.default.openSync(opt.file, "r+");
        } catch (er) {
          if (er?.code === "ENOENT") {
            fd = node_fs_1.default.openSync(opt.file, "w+");
          } else {
            throw er;
          }
        }
        const st = node_fs_1.default.fstatSync(fd);
        const headBuf = Buffer.alloc(512);
        POSITION: for (position = 0; position < st.size; position += 512) {
          for (let bufPos = 0, bytes = 0; bufPos < 512; bufPos += bytes) {
            bytes = node_fs_1.default.readSync(fd, headBuf, bufPos, headBuf.length - bufPos, position + bufPos);
            if (position === 0 && headBuf[0] === 31 && headBuf[1] === 139) {
              throw new Error("cannot append to compressed archives");
            }
            if (!bytes) {
              break POSITION;
            }
          }
          const h = new header_js_1.Header(headBuf);
          if (!h.cksumValid) {
            break;
          }
          const entryBlockSize = 512 * Math.ceil((h.size || 0) / 512);
          if (position + entryBlockSize + 512 > st.size) {
            break;
          }
          position += entryBlockSize;
          if (opt.mtimeCache && h.mtime) {
            opt.mtimeCache.set(String(h.path), h.mtime);
          }
        }
        threw = false;
        streamSync(opt, p, position, fd, files);
      } finally {
        if (threw) {
          try {
            node_fs_1.default.closeSync(fd);
          } catch {
          }
        }
      }
    };
    var streamSync = (opt, p, position, fd, files) => {
      const stream = new fs_minipass_1.WriteStreamSync(opt.file, {
        fd,
        start: position
      });
      p.pipe(stream);
      addFilesSync(p, files);
    };
    var replaceAsync = (opt, files) => {
      files = Array.from(files);
      const p = new pack_js_1.Pack(opt);
      const getPos = (fd, size, cb_) => {
        const cb = (er, pos) => {
          if (er) {
            node_fs_1.default.close(fd, (_) => cb_(er));
          } else {
            cb_(null, pos);
          }
        };
        let position = 0;
        if (size === 0) {
          return cb(null, 0);
        }
        let bufPos = 0;
        const headBuf = Buffer.alloc(512);
        const onread = (er, bytes) => {
          if (er || bytes === void 0) {
            return cb(er);
          }
          bufPos += bytes;
          if (bufPos < 512 && bytes) {
            return node_fs_1.default.read(fd, headBuf, bufPos, headBuf.length - bufPos, position + bufPos, onread);
          }
          if (position === 0 && headBuf[0] === 31 && headBuf[1] === 139) {
            return cb(new Error("cannot append to compressed archives"));
          }
          if (bufPos < 512) {
            return cb(null, position);
          }
          const h = new header_js_1.Header(headBuf);
          if (!h.cksumValid) {
            return cb(null, position);
          }
          const entryBlockSize = 512 * Math.ceil((h.size ?? 0) / 512);
          if (position + entryBlockSize + 512 > size) {
            return cb(null, position);
          }
          position += entryBlockSize + 512;
          if (position >= size) {
            return cb(null, position);
          }
          if (opt.mtimeCache && h.mtime) {
            opt.mtimeCache.set(String(h.path), h.mtime);
          }
          bufPos = 0;
          node_fs_1.default.read(fd, headBuf, 0, 512, position, onread);
        };
        node_fs_1.default.read(fd, headBuf, 0, 512, position, onread);
      };
      const promise = new Promise((resolve, reject) => {
        p.on("error", reject);
        let flag = "r+";
        const onopen = (er, fd) => {
          if (er && er.code === "ENOENT" && flag === "r+") {
            flag = "w+";
            return node_fs_1.default.open(opt.file, flag, onopen);
          }
          if (er || !fd) {
            return reject(er);
          }
          node_fs_1.default.fstat(fd, (er2, st) => {
            if (er2) {
              return node_fs_1.default.close(fd, () => reject(er2));
            }
            getPos(fd, st.size, (er3, position) => {
              if (er3) {
                return reject(er3);
              }
              const stream = new fs_minipass_1.WriteStream(opt.file, {
                fd,
                start: position
              });
              p.pipe(stream);
              stream.on("error", reject);
              stream.on("close", resolve);
              addFilesAsync(p, files);
            });
          });
        };
        node_fs_1.default.open(opt.file, flag, onopen);
      });
      return promise;
    };
    var addFilesSync = (p, files) => {
      files.forEach((file) => {
        if (file.charAt(0) === "@") {
          (0, list_js_1.list)({
            file: node_path_1.default.resolve(p.cwd, file.slice(1)),
            sync: true,
            noResume: true,
            onReadEntry: (entry) => p.add(entry)
          });
        } else {
          p.add(file);
        }
      });
      p.end();
    };
    var addFilesAsync = async (p, files) => {
      for (const file of files) {
        if (file.charAt(0) === "@") {
          await (0, list_js_1.list)({
            file: node_path_1.default.resolve(String(p.cwd), file.slice(1)),
            noResume: true,
            onReadEntry: (entry) => p.add(entry)
          });
        } else {
          p.add(file);
        }
      }
      p.end();
    };
    exports2.replace = (0, make_command_js_1.makeCommand)(
      replaceSync,
      replaceAsync,
      /* c8 ignore start */
      () => {
        throw new TypeError("file is required");
      },
      () => {
        throw new TypeError("file is required");
      },
      /* c8 ignore stop */
      (opt, entries) => {
        if (!(0, options_js_1.isFile)(opt)) {
          throw new TypeError("file is required");
        }
        if (opt.gzip || opt.brotli || opt.zstd || opt.file.endsWith(".br") || opt.file.endsWith(".tbr")) {
          throw new TypeError("cannot append to compressed archives");
        }
        if (!entries?.length) {
          throw new TypeError("no paths specified to add/replace");
        }
      }
    );
  }
});

// ../node_modules/tar/dist/commonjs/update.js
var require_update = __commonJS({
  "../node_modules/tar/dist/commonjs/update.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.update = void 0;
    var make_command_js_1 = require_make_command();
    var replace_js_1 = require_replace();
    exports2.update = (0, make_command_js_1.makeCommand)(replace_js_1.replace.syncFile, replace_js_1.replace.asyncFile, replace_js_1.replace.syncNoFile, replace_js_1.replace.asyncNoFile, (opt, entries = []) => {
      replace_js_1.replace.validate?.(opt, entries);
      mtimeFilter(opt);
    });
    var mtimeFilter = (opt) => {
      const filter = opt.filter;
      if (!opt.mtimeCache) {
        opt.mtimeCache = /* @__PURE__ */ new Map();
      }
      opt.filter = filter ? (path2, stat) => filter(path2, stat) && !/* c8 ignore start */
      ((opt.mtimeCache?.get(path2) ?? stat.mtime ?? 0) > (stat.mtime ?? 0)) : (path2, stat) => !/* c8 ignore start */
      ((opt.mtimeCache?.get(path2) ?? stat.mtime ?? 0) > (stat.mtime ?? 0));
    };
  }
});

// ../node_modules/tar/dist/commonjs/index.js
var require_commonjs7 = __commonJS({
  "../node_modules/tar/dist/commonjs/index.js"(exports2) {
    "use strict";
    var __createBinding = exports2 && exports2.__createBinding || (Object.create ? (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      var desc = Object.getOwnPropertyDescriptor(m, k);
      if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() {
          return m[k];
        } };
      }
      Object.defineProperty(o, k2, desc);
    }) : (function(o, m, k, k2) {
      if (k2 === void 0) k2 = k;
      o[k2] = m[k];
    }));
    var __setModuleDefault = exports2 && exports2.__setModuleDefault || (Object.create ? (function(o, v) {
      Object.defineProperty(o, "default", { enumerable: true, value: v });
    }) : function(o, v) {
      o["default"] = v;
    });
    var __exportStar = exports2 && exports2.__exportStar || function(m, exports3) {
      for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports3, p)) __createBinding(exports3, m, p);
    };
    var __importStar = exports2 && exports2.__importStar || /* @__PURE__ */ (function() {
      var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function(o2) {
          var ar = [];
          for (var k in o2) if (Object.prototype.hasOwnProperty.call(o2, k)) ar[ar.length] = k;
          return ar;
        };
        return ownKeys(o);
      };
      return function(mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) {
          for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        }
        __setModuleDefault(result, mod);
        return result;
      };
    })();
    Object.defineProperty(exports2, "__esModule", { value: true });
    exports2.u = exports2.types = exports2.r = exports2.t = exports2.x = exports2.c = void 0;
    __exportStar(require_create(), exports2);
    var create_js_1 = require_create();
    Object.defineProperty(exports2, "c", { enumerable: true, get: function() {
      return create_js_1.create;
    } });
    __exportStar(require_extract(), exports2);
    var extract_js_1 = require_extract();
    Object.defineProperty(exports2, "x", { enumerable: true, get: function() {
      return extract_js_1.extract;
    } });
    __exportStar(require_header(), exports2);
    __exportStar(require_list(), exports2);
    var list_js_1 = require_list();
    Object.defineProperty(exports2, "t", { enumerable: true, get: function() {
      return list_js_1.list;
    } });
    __exportStar(require_pack(), exports2);
    __exportStar(require_parse(), exports2);
    __exportStar(require_pax(), exports2);
    __exportStar(require_read_entry(), exports2);
    __exportStar(require_replace(), exports2);
    var replace_js_1 = require_replace();
    Object.defineProperty(exports2, "r", { enumerable: true, get: function() {
      return replace_js_1.replace;
    } });
    exports2.types = __importStar(require_types());
    __exportStar(require_unpack(), exports2);
    __exportStar(require_update(), exports2);
    var update_js_1 = require_update();
    Object.defineProperty(exports2, "u", { enumerable: true, get: function() {
      return update_js_1.update;
    } });
    __exportStar(require_write_entry(), exports2);
  }
});

// ../../../node_modules/graceful-fs/polyfills.js
var require_polyfills = __commonJS({
  "../../../node_modules/graceful-fs/polyfills.js"(exports2, module2) {
    var constants = require("constants");
    var origCwd = process.cwd;
    var cwd = null;
    var platform = process.env.GRACEFUL_FS_PLATFORM || process.platform;
    process.cwd = function() {
      if (!cwd)
        cwd = origCwd.call(process);
      return cwd;
    };
    try {
      process.cwd();
    } catch (er) {
    }
    if (typeof process.chdir === "function") {
      chdir = process.chdir;
      process.chdir = function(d) {
        cwd = null;
        chdir.call(process, d);
      };
      if (Object.setPrototypeOf) Object.setPrototypeOf(process.chdir, chdir);
    }
    var chdir;
    module2.exports = patch;
    function patch(fs2) {
      if (constants.hasOwnProperty("O_SYMLINK") && process.version.match(/^v0\.6\.[0-2]|^v0\.5\./)) {
        patchLchmod(fs2);
      }
      if (!fs2.lutimes) {
        patchLutimes(fs2);
      }
      fs2.chown = chownFix(fs2.chown);
      fs2.fchown = chownFix(fs2.fchown);
      fs2.lchown = chownFix(fs2.lchown);
      fs2.chmod = chmodFix(fs2.chmod);
      fs2.fchmod = chmodFix(fs2.fchmod);
      fs2.lchmod = chmodFix(fs2.lchmod);
      fs2.chownSync = chownFixSync(fs2.chownSync);
      fs2.fchownSync = chownFixSync(fs2.fchownSync);
      fs2.lchownSync = chownFixSync(fs2.lchownSync);
      fs2.chmodSync = chmodFixSync(fs2.chmodSync);
      fs2.fchmodSync = chmodFixSync(fs2.fchmodSync);
      fs2.lchmodSync = chmodFixSync(fs2.lchmodSync);
      fs2.stat = statFix(fs2.stat);
      fs2.fstat = statFix(fs2.fstat);
      fs2.lstat = statFix(fs2.lstat);
      fs2.statSync = statFixSync(fs2.statSync);
      fs2.fstatSync = statFixSync(fs2.fstatSync);
      fs2.lstatSync = statFixSync(fs2.lstatSync);
      if (fs2.chmod && !fs2.lchmod) {
        fs2.lchmod = function(path2, mode, cb) {
          if (cb) process.nextTick(cb);
        };
        fs2.lchmodSync = function() {
        };
      }
      if (fs2.chown && !fs2.lchown) {
        fs2.lchown = function(path2, uid, gid, cb) {
          if (cb) process.nextTick(cb);
        };
        fs2.lchownSync = function() {
        };
      }
      if (platform === "win32") {
        fs2.rename = typeof fs2.rename !== "function" ? fs2.rename : (function(fs$rename) {
          function rename(from, to, cb) {
            var start = Date.now();
            var backoff = 0;
            fs$rename(from, to, function CB(er) {
              if (er && (er.code === "EACCES" || er.code === "EPERM" || er.code === "EBUSY") && Date.now() - start < 6e4) {
                setTimeout(function() {
                  fs2.stat(to, function(stater, st) {
                    if (stater && stater.code === "ENOENT")
                      fs$rename(from, to, CB);
                    else
                      cb(er);
                  });
                }, backoff);
                if (backoff < 100)
                  backoff += 10;
                return;
              }
              if (cb) cb(er);
            });
          }
          if (Object.setPrototypeOf) Object.setPrototypeOf(rename, fs$rename);
          return rename;
        })(fs2.rename);
      }
      fs2.read = typeof fs2.read !== "function" ? fs2.read : (function(fs$read) {
        function read(fd, buffer, offset, length, position, callback_) {
          var callback;
          if (callback_ && typeof callback_ === "function") {
            var eagCounter = 0;
            callback = function(er, _, __) {
              if (er && er.code === "EAGAIN" && eagCounter < 10) {
                eagCounter++;
                return fs$read.call(fs2, fd, buffer, offset, length, position, callback);
              }
              callback_.apply(this, arguments);
            };
          }
          return fs$read.call(fs2, fd, buffer, offset, length, position, callback);
        }
        if (Object.setPrototypeOf) Object.setPrototypeOf(read, fs$read);
        return read;
      })(fs2.read);
      fs2.readSync = typeof fs2.readSync !== "function" ? fs2.readSync : /* @__PURE__ */ (function(fs$readSync) {
        return function(fd, buffer, offset, length, position) {
          var eagCounter = 0;
          while (true) {
            try {
              return fs$readSync.call(fs2, fd, buffer, offset, length, position);
            } catch (er) {
              if (er.code === "EAGAIN" && eagCounter < 10) {
                eagCounter++;
                continue;
              }
              throw er;
            }
          }
        };
      })(fs2.readSync);
      function patchLchmod(fs3) {
        fs3.lchmod = function(path2, mode, callback) {
          fs3.open(
            path2,
            constants.O_WRONLY | constants.O_SYMLINK,
            mode,
            function(err, fd) {
              if (err) {
                if (callback) callback(err);
                return;
              }
              fs3.fchmod(fd, mode, function(err2) {
                fs3.close(fd, function(err22) {
                  if (callback) callback(err2 || err22);
                });
              });
            }
          );
        };
        fs3.lchmodSync = function(path2, mode) {
          var fd = fs3.openSync(path2, constants.O_WRONLY | constants.O_SYMLINK, mode);
          var threw = true;
          var ret;
          try {
            ret = fs3.fchmodSync(fd, mode);
            threw = false;
          } finally {
            if (threw) {
              try {
                fs3.closeSync(fd);
              } catch (er) {
              }
            } else {
              fs3.closeSync(fd);
            }
          }
          return ret;
        };
      }
      function patchLutimes(fs3) {
        if (constants.hasOwnProperty("O_SYMLINK") && fs3.futimes) {
          fs3.lutimes = function(path2, at, mt, cb) {
            fs3.open(path2, constants.O_SYMLINK, function(er, fd) {
              if (er) {
                if (cb) cb(er);
                return;
              }
              fs3.futimes(fd, at, mt, function(er2) {
                fs3.close(fd, function(er22) {
                  if (cb) cb(er2 || er22);
                });
              });
            });
          };
          fs3.lutimesSync = function(path2, at, mt) {
            var fd = fs3.openSync(path2, constants.O_SYMLINK);
            var ret;
            var threw = true;
            try {
              ret = fs3.futimesSync(fd, at, mt);
              threw = false;
            } finally {
              if (threw) {
                try {
                  fs3.closeSync(fd);
                } catch (er) {
                }
              } else {
                fs3.closeSync(fd);
              }
            }
            return ret;
          };
        } else if (fs3.futimes) {
          fs3.lutimes = function(_a, _b, _c, cb) {
            if (cb) process.nextTick(cb);
          };
          fs3.lutimesSync = function() {
          };
        }
      }
      function chmodFix(orig) {
        if (!orig) return orig;
        return function(target, mode, cb) {
          return orig.call(fs2, target, mode, function(er) {
            if (chownErOk(er)) er = null;
            if (cb) cb.apply(this, arguments);
          });
        };
      }
      function chmodFixSync(orig) {
        if (!orig) return orig;
        return function(target, mode) {
          try {
            return orig.call(fs2, target, mode);
          } catch (er) {
            if (!chownErOk(er)) throw er;
          }
        };
      }
      function chownFix(orig) {
        if (!orig) return orig;
        return function(target, uid, gid, cb) {
          return orig.call(fs2, target, uid, gid, function(er) {
            if (chownErOk(er)) er = null;
            if (cb) cb.apply(this, arguments);
          });
        };
      }
      function chownFixSync(orig) {
        if (!orig) return orig;
        return function(target, uid, gid) {
          try {
            return orig.call(fs2, target, uid, gid);
          } catch (er) {
            if (!chownErOk(er)) throw er;
          }
        };
      }
      function statFix(orig) {
        if (!orig) return orig;
        return function(target, options, cb) {
          if (typeof options === "function") {
            cb = options;
            options = null;
          }
          function callback(er, stats) {
            if (stats) {
              if (stats.uid < 0) stats.uid += 4294967296;
              if (stats.gid < 0) stats.gid += 4294967296;
            }
            if (cb) cb.apply(this, arguments);
          }
          return options ? orig.call(fs2, target, options, callback) : orig.call(fs2, target, callback);
        };
      }
      function statFixSync(orig) {
        if (!orig) return orig;
        return function(target, options) {
          var stats = options ? orig.call(fs2, target, options) : orig.call(fs2, target);
          if (stats) {
            if (stats.uid < 0) stats.uid += 4294967296;
            if (stats.gid < 0) stats.gid += 4294967296;
          }
          return stats;
        };
      }
      function chownErOk(er) {
        if (!er)
          return true;
        if (er.code === "ENOSYS")
          return true;
        var nonroot = !process.getuid || process.getuid() !== 0;
        if (nonroot) {
          if (er.code === "EINVAL" || er.code === "EPERM")
            return true;
        }
        return false;
      }
    }
  }
});

// ../../../node_modules/graceful-fs/legacy-streams.js
var require_legacy_streams = __commonJS({
  "../../../node_modules/graceful-fs/legacy-streams.js"(exports2, module2) {
    var Stream = require("stream").Stream;
    module2.exports = legacy;
    function legacy(fs2) {
      return {
        ReadStream,
        WriteStream
      };
      function ReadStream(path2, options) {
        if (!(this instanceof ReadStream)) return new ReadStream(path2, options);
        Stream.call(this);
        var self = this;
        this.path = path2;
        this.fd = null;
        this.readable = true;
        this.paused = false;
        this.flags = "r";
        this.mode = 438;
        this.bufferSize = 64 * 1024;
        options = options || {};
        var keys = Object.keys(options);
        for (var index = 0, length = keys.length; index < length; index++) {
          var key = keys[index];
          this[key] = options[key];
        }
        if (this.encoding) this.setEncoding(this.encoding);
        if (this.start !== void 0) {
          if ("number" !== typeof this.start) {
            throw TypeError("start must be a Number");
          }
          if (this.end === void 0) {
            this.end = Infinity;
          } else if ("number" !== typeof this.end) {
            throw TypeError("end must be a Number");
          }
          if (this.start > this.end) {
            throw new Error("start must be <= end");
          }
          this.pos = this.start;
        }
        if (this.fd !== null) {
          process.nextTick(function() {
            self._read();
          });
          return;
        }
        fs2.open(this.path, this.flags, this.mode, function(err, fd) {
          if (err) {
            self.emit("error", err);
            self.readable = false;
            return;
          }
          self.fd = fd;
          self.emit("open", fd);
          self._read();
        });
      }
      function WriteStream(path2, options) {
        if (!(this instanceof WriteStream)) return new WriteStream(path2, options);
        Stream.call(this);
        this.path = path2;
        this.fd = null;
        this.writable = true;
        this.flags = "w";
        this.encoding = "binary";
        this.mode = 438;
        this.bytesWritten = 0;
        options = options || {};
        var keys = Object.keys(options);
        for (var index = 0, length = keys.length; index < length; index++) {
          var key = keys[index];
          this[key] = options[key];
        }
        if (this.start !== void 0) {
          if ("number" !== typeof this.start) {
            throw TypeError("start must be a Number");
          }
          if (this.start < 0) {
            throw new Error("start must be >= zero");
          }
          this.pos = this.start;
        }
        this.busy = false;
        this._queue = [];
        if (this.fd === null) {
          this._open = fs2.open;
          this._queue.push([this._open, this.path, this.flags, this.mode, void 0]);
          this.flush();
        }
      }
    }
  }
});

// ../../../node_modules/graceful-fs/clone.js
var require_clone = __commonJS({
  "../../../node_modules/graceful-fs/clone.js"(exports2, module2) {
    "use strict";
    module2.exports = clone;
    var getPrototypeOf = Object.getPrototypeOf || function(obj) {
      return obj.__proto__;
    };
    function clone(obj) {
      if (obj === null || typeof obj !== "object")
        return obj;
      if (obj instanceof Object)
        var copy = { __proto__: getPrototypeOf(obj) };
      else
        var copy = /* @__PURE__ */ Object.create(null);
      Object.getOwnPropertyNames(obj).forEach(function(key) {
        Object.defineProperty(copy, key, Object.getOwnPropertyDescriptor(obj, key));
      });
      return copy;
    }
  }
});

// ../../../node_modules/graceful-fs/graceful-fs.js
var require_graceful_fs = __commonJS({
  "../../../node_modules/graceful-fs/graceful-fs.js"(exports2, module2) {
    var fs2 = require("fs");
    var polyfills = require_polyfills();
    var legacy = require_legacy_streams();
    var clone = require_clone();
    var util = require("util");
    var gracefulQueue;
    var previousSymbol;
    if (typeof Symbol === "function" && typeof Symbol.for === "function") {
      gracefulQueue = /* @__PURE__ */ Symbol.for("graceful-fs.queue");
      previousSymbol = /* @__PURE__ */ Symbol.for("graceful-fs.previous");
    } else {
      gracefulQueue = "___graceful-fs.queue";
      previousSymbol = "___graceful-fs.previous";
    }
    function noop() {
    }
    function publishQueue(context, queue2) {
      Object.defineProperty(context, gracefulQueue, {
        get: function() {
          return queue2;
        }
      });
    }
    var debug = noop;
    if (util.debuglog)
      debug = util.debuglog("gfs4");
    else if (/\bgfs4\b/i.test(process.env.NODE_DEBUG || ""))
      debug = function() {
        var m = util.format.apply(util, arguments);
        m = "GFS4: " + m.split(/\n/).join("\nGFS4: ");
        console.error(m);
      };
    if (!fs2[gracefulQueue]) {
      queue = global[gracefulQueue] || [];
      publishQueue(fs2, queue);
      fs2.close = (function(fs$close) {
        function close(fd, cb) {
          return fs$close.call(fs2, fd, function(err) {
            if (!err) {
              resetQueue();
            }
            if (typeof cb === "function")
              cb.apply(this, arguments);
          });
        }
        Object.defineProperty(close, previousSymbol, {
          value: fs$close
        });
        return close;
      })(fs2.close);
      fs2.closeSync = (function(fs$closeSync) {
        function closeSync(fd) {
          fs$closeSync.apply(fs2, arguments);
          resetQueue();
        }
        Object.defineProperty(closeSync, previousSymbol, {
          value: fs$closeSync
        });
        return closeSync;
      })(fs2.closeSync);
      if (/\bgfs4\b/i.test(process.env.NODE_DEBUG || "")) {
        process.on("exit", function() {
          debug(fs2[gracefulQueue]);
          require("assert").equal(fs2[gracefulQueue].length, 0);
        });
      }
    }
    var queue;
    if (!global[gracefulQueue]) {
      publishQueue(global, fs2[gracefulQueue]);
    }
    module2.exports = patch(clone(fs2));
    if (process.env.TEST_GRACEFUL_FS_GLOBAL_PATCH && !fs2.__patched) {
      module2.exports = patch(fs2);
      fs2.__patched = true;
    }
    function patch(fs3) {
      polyfills(fs3);
      fs3.gracefulify = patch;
      fs3.createReadStream = createReadStream;
      fs3.createWriteStream = createWriteStream;
      var fs$readFile = fs3.readFile;
      fs3.readFile = readFile;
      function readFile(path2, options, cb) {
        if (typeof options === "function")
          cb = options, options = null;
        return go$readFile(path2, options, cb);
        function go$readFile(path3, options2, cb2, startTime) {
          return fs$readFile(path3, options2, function(err) {
            if (err && (err.code === "EMFILE" || err.code === "ENFILE"))
              enqueue([go$readFile, [path3, options2, cb2], err, startTime || Date.now(), Date.now()]);
            else {
              if (typeof cb2 === "function")
                cb2.apply(this, arguments);
            }
          });
        }
      }
      var fs$writeFile = fs3.writeFile;
      fs3.writeFile = writeFile;
      function writeFile(path2, data, options, cb) {
        if (typeof options === "function")
          cb = options, options = null;
        return go$writeFile(path2, data, options, cb);
        function go$writeFile(path3, data2, options2, cb2, startTime) {
          return fs$writeFile(path3, data2, options2, function(err) {
            if (err && (err.code === "EMFILE" || err.code === "ENFILE"))
              enqueue([go$writeFile, [path3, data2, options2, cb2], err, startTime || Date.now(), Date.now()]);
            else {
              if (typeof cb2 === "function")
                cb2.apply(this, arguments);
            }
          });
        }
      }
      var fs$appendFile = fs3.appendFile;
      if (fs$appendFile)
        fs3.appendFile = appendFile;
      function appendFile(path2, data, options, cb) {
        if (typeof options === "function")
          cb = options, options = null;
        return go$appendFile(path2, data, options, cb);
        function go$appendFile(path3, data2, options2, cb2, startTime) {
          return fs$appendFile(path3, data2, options2, function(err) {
            if (err && (err.code === "EMFILE" || err.code === "ENFILE"))
              enqueue([go$appendFile, [path3, data2, options2, cb2], err, startTime || Date.now(), Date.now()]);
            else {
              if (typeof cb2 === "function")
                cb2.apply(this, arguments);
            }
          });
        }
      }
      var fs$copyFile = fs3.copyFile;
      if (fs$copyFile)
        fs3.copyFile = copyFile;
      function copyFile(src, dest, flags, cb) {
        if (typeof flags === "function") {
          cb = flags;
          flags = 0;
        }
        return go$copyFile(src, dest, flags, cb);
        function go$copyFile(src2, dest2, flags2, cb2, startTime) {
          return fs$copyFile(src2, dest2, flags2, function(err) {
            if (err && (err.code === "EMFILE" || err.code === "ENFILE"))
              enqueue([go$copyFile, [src2, dest2, flags2, cb2], err, startTime || Date.now(), Date.now()]);
            else {
              if (typeof cb2 === "function")
                cb2.apply(this, arguments);
            }
          });
        }
      }
      var fs$readdir = fs3.readdir;
      fs3.readdir = readdir;
      var noReaddirOptionVersions = /^v[0-5]\./;
      function readdir(path2, options, cb) {
        if (typeof options === "function")
          cb = options, options = null;
        var go$readdir = noReaddirOptionVersions.test(process.version) ? function go$readdir2(path3, options2, cb2, startTime) {
          return fs$readdir(path3, fs$readdirCallback(
            path3,
            options2,
            cb2,
            startTime
          ));
        } : function go$readdir2(path3, options2, cb2, startTime) {
          return fs$readdir(path3, options2, fs$readdirCallback(
            path3,
            options2,
            cb2,
            startTime
          ));
        };
        return go$readdir(path2, options, cb);
        function fs$readdirCallback(path3, options2, cb2, startTime) {
          return function(err, files) {
            if (err && (err.code === "EMFILE" || err.code === "ENFILE"))
              enqueue([
                go$readdir,
                [path3, options2, cb2],
                err,
                startTime || Date.now(),
                Date.now()
              ]);
            else {
              if (files && files.sort)
                files.sort();
              if (typeof cb2 === "function")
                cb2.call(this, err, files);
            }
          };
        }
      }
      if (process.version.substr(0, 4) === "v0.8") {
        var legStreams = legacy(fs3);
        ReadStream = legStreams.ReadStream;
        WriteStream = legStreams.WriteStream;
      }
      var fs$ReadStream = fs3.ReadStream;
      if (fs$ReadStream) {
        ReadStream.prototype = Object.create(fs$ReadStream.prototype);
        ReadStream.prototype.open = ReadStream$open;
      }
      var fs$WriteStream = fs3.WriteStream;
      if (fs$WriteStream) {
        WriteStream.prototype = Object.create(fs$WriteStream.prototype);
        WriteStream.prototype.open = WriteStream$open;
      }
      Object.defineProperty(fs3, "ReadStream", {
        get: function() {
          return ReadStream;
        },
        set: function(val) {
          ReadStream = val;
        },
        enumerable: true,
        configurable: true
      });
      Object.defineProperty(fs3, "WriteStream", {
        get: function() {
          return WriteStream;
        },
        set: function(val) {
          WriteStream = val;
        },
        enumerable: true,
        configurable: true
      });
      var FileReadStream = ReadStream;
      Object.defineProperty(fs3, "FileReadStream", {
        get: function() {
          return FileReadStream;
        },
        set: function(val) {
          FileReadStream = val;
        },
        enumerable: true,
        configurable: true
      });
      var FileWriteStream = WriteStream;
      Object.defineProperty(fs3, "FileWriteStream", {
        get: function() {
          return FileWriteStream;
        },
        set: function(val) {
          FileWriteStream = val;
        },
        enumerable: true,
        configurable: true
      });
      function ReadStream(path2, options) {
        if (this instanceof ReadStream)
          return fs$ReadStream.apply(this, arguments), this;
        else
          return ReadStream.apply(Object.create(ReadStream.prototype), arguments);
      }
      function ReadStream$open() {
        var that = this;
        open(that.path, that.flags, that.mode, function(err, fd) {
          if (err) {
            if (that.autoClose)
              that.destroy();
            that.emit("error", err);
          } else {
            that.fd = fd;
            that.emit("open", fd);
            that.read();
          }
        });
      }
      function WriteStream(path2, options) {
        if (this instanceof WriteStream)
          return fs$WriteStream.apply(this, arguments), this;
        else
          return WriteStream.apply(Object.create(WriteStream.prototype), arguments);
      }
      function WriteStream$open() {
        var that = this;
        open(that.path, that.flags, that.mode, function(err, fd) {
          if (err) {
            that.destroy();
            that.emit("error", err);
          } else {
            that.fd = fd;
            that.emit("open", fd);
          }
        });
      }
      function createReadStream(path2, options) {
        return new fs3.ReadStream(path2, options);
      }
      function createWriteStream(path2, options) {
        return new fs3.WriteStream(path2, options);
      }
      var fs$open = fs3.open;
      fs3.open = open;
      function open(path2, flags, mode, cb) {
        if (typeof mode === "function")
          cb = mode, mode = null;
        return go$open(path2, flags, mode, cb);
        function go$open(path3, flags2, mode2, cb2, startTime) {
          return fs$open(path3, flags2, mode2, function(err, fd) {
            if (err && (err.code === "EMFILE" || err.code === "ENFILE"))
              enqueue([go$open, [path3, flags2, mode2, cb2], err, startTime || Date.now(), Date.now()]);
            else {
              if (typeof cb2 === "function")
                cb2.apply(this, arguments);
            }
          });
        }
      }
      return fs3;
    }
    function enqueue(elem) {
      debug("ENQUEUE", elem[0].name, elem[1]);
      fs2[gracefulQueue].push(elem);
      retry();
    }
    var retryTimer;
    function resetQueue() {
      var now = Date.now();
      for (var i = 0; i < fs2[gracefulQueue].length; ++i) {
        if (fs2[gracefulQueue][i].length > 2) {
          fs2[gracefulQueue][i][3] = now;
          fs2[gracefulQueue][i][4] = now;
        }
      }
      retry();
    }
    function retry() {
      clearTimeout(retryTimer);
      retryTimer = void 0;
      if (fs2[gracefulQueue].length === 0)
        return;
      var elem = fs2[gracefulQueue].shift();
      var fn = elem[0];
      var args = elem[1];
      var err = elem[2];
      var startTime = elem[3];
      var lastTime = elem[4];
      if (startTime === void 0) {
        debug("RETRY", fn.name, args);
        fn.apply(null, args);
      } else if (Date.now() - startTime >= 6e4) {
        debug("TIMEOUT", fn.name, args);
        var cb = args.pop();
        if (typeof cb === "function")
          cb.call(null, err);
      } else {
        var sinceAttempt = Date.now() - lastTime;
        var sinceStart = Math.max(lastTime - startTime, 1);
        var desiredDelay = Math.min(sinceStart * 1.2, 100);
        if (sinceAttempt >= desiredDelay) {
          debug("RETRY", fn.name, args);
          fn.apply(null, args.concat([startTime]));
        } else {
          fs2[gracefulQueue].push(elem);
        }
      }
      if (retryTimer === void 0) {
        retryTimer = setTimeout(retry, 0);
      }
    }
  }
});

// ../../../node_modules/retry/lib/retry_operation.js
var require_retry_operation = __commonJS({
  "../../../node_modules/retry/lib/retry_operation.js"(exports2, module2) {
    function RetryOperation(timeouts, options) {
      if (typeof options === "boolean") {
        options = { forever: options };
      }
      this._originalTimeouts = JSON.parse(JSON.stringify(timeouts));
      this._timeouts = timeouts;
      this._options = options || {};
      this._maxRetryTime = options && options.maxRetryTime || Infinity;
      this._fn = null;
      this._errors = [];
      this._attempts = 1;
      this._operationTimeout = null;
      this._operationTimeoutCb = null;
      this._timeout = null;
      this._operationStart = null;
      if (this._options.forever) {
        this._cachedTimeouts = this._timeouts.slice(0);
      }
    }
    module2.exports = RetryOperation;
    RetryOperation.prototype.reset = function() {
      this._attempts = 1;
      this._timeouts = this._originalTimeouts;
    };
    RetryOperation.prototype.stop = function() {
      if (this._timeout) {
        clearTimeout(this._timeout);
      }
      this._timeouts = [];
      this._cachedTimeouts = null;
    };
    RetryOperation.prototype.retry = function(err) {
      if (this._timeout) {
        clearTimeout(this._timeout);
      }
      if (!err) {
        return false;
      }
      var currentTime = (/* @__PURE__ */ new Date()).getTime();
      if (err && currentTime - this._operationStart >= this._maxRetryTime) {
        this._errors.unshift(new Error("RetryOperation timeout occurred"));
        return false;
      }
      this._errors.push(err);
      var timeout = this._timeouts.shift();
      if (timeout === void 0) {
        if (this._cachedTimeouts) {
          this._errors.splice(this._errors.length - 1, this._errors.length);
          this._timeouts = this._cachedTimeouts.slice(0);
          timeout = this._timeouts.shift();
        } else {
          return false;
        }
      }
      var self = this;
      var timer = setTimeout(function() {
        self._attempts++;
        if (self._operationTimeoutCb) {
          self._timeout = setTimeout(function() {
            self._operationTimeoutCb(self._attempts);
          }, self._operationTimeout);
          if (self._options.unref) {
            self._timeout.unref();
          }
        }
        self._fn(self._attempts);
      }, timeout);
      if (this._options.unref) {
        timer.unref();
      }
      return true;
    };
    RetryOperation.prototype.attempt = function(fn, timeoutOps) {
      this._fn = fn;
      if (timeoutOps) {
        if (timeoutOps.timeout) {
          this._operationTimeout = timeoutOps.timeout;
        }
        if (timeoutOps.cb) {
          this._operationTimeoutCb = timeoutOps.cb;
        }
      }
      var self = this;
      if (this._operationTimeoutCb) {
        this._timeout = setTimeout(function() {
          self._operationTimeoutCb();
        }, self._operationTimeout);
      }
      this._operationStart = (/* @__PURE__ */ new Date()).getTime();
      this._fn(this._attempts);
    };
    RetryOperation.prototype.try = function(fn) {
      console.log("Using RetryOperation.try() is deprecated");
      this.attempt(fn);
    };
    RetryOperation.prototype.start = function(fn) {
      console.log("Using RetryOperation.start() is deprecated");
      this.attempt(fn);
    };
    RetryOperation.prototype.start = RetryOperation.prototype.try;
    RetryOperation.prototype.errors = function() {
      return this._errors;
    };
    RetryOperation.prototype.attempts = function() {
      return this._attempts;
    };
    RetryOperation.prototype.mainError = function() {
      if (this._errors.length === 0) {
        return null;
      }
      var counts = {};
      var mainError = null;
      var mainErrorCount = 0;
      for (var i = 0; i < this._errors.length; i++) {
        var error = this._errors[i];
        var message = error.message;
        var count = (counts[message] || 0) + 1;
        counts[message] = count;
        if (count >= mainErrorCount) {
          mainError = error;
          mainErrorCount = count;
        }
      }
      return mainError;
    };
  }
});

// ../../../node_modules/retry/lib/retry.js
var require_retry = __commonJS({
  "../../../node_modules/retry/lib/retry.js"(exports2) {
    var RetryOperation = require_retry_operation();
    exports2.operation = function(options) {
      var timeouts = exports2.timeouts(options);
      return new RetryOperation(timeouts, {
        forever: options && options.forever,
        unref: options && options.unref,
        maxRetryTime: options && options.maxRetryTime
      });
    };
    exports2.timeouts = function(options) {
      if (options instanceof Array) {
        return [].concat(options);
      }
      var opts = {
        retries: 10,
        factor: 2,
        minTimeout: 1 * 1e3,
        maxTimeout: Infinity,
        randomize: false
      };
      for (var key in options) {
        opts[key] = options[key];
      }
      if (opts.minTimeout > opts.maxTimeout) {
        throw new Error("minTimeout is greater than maxTimeout");
      }
      var timeouts = [];
      for (var i = 0; i < opts.retries; i++) {
        timeouts.push(this.createTimeout(i, opts));
      }
      if (options && options.forever && !timeouts.length) {
        timeouts.push(this.createTimeout(i, opts));
      }
      timeouts.sort(function(a, b) {
        return a - b;
      });
      return timeouts;
    };
    exports2.createTimeout = function(attempt, opts) {
      var random = opts.randomize ? Math.random() + 1 : 1;
      var timeout = Math.round(random * opts.minTimeout * Math.pow(opts.factor, attempt));
      timeout = Math.min(timeout, opts.maxTimeout);
      return timeout;
    };
    exports2.wrap = function(obj, options, methods) {
      if (options instanceof Array) {
        methods = options;
        options = null;
      }
      if (!methods) {
        methods = [];
        for (var key in obj) {
          if (typeof obj[key] === "function") {
            methods.push(key);
          }
        }
      }
      for (var i = 0; i < methods.length; i++) {
        var method = methods[i];
        var original = obj[method];
        obj[method] = function retryWrapper(original2) {
          var op = exports2.operation(options);
          var args = Array.prototype.slice.call(arguments, 1);
          var callback = args.pop();
          args.push(function(err) {
            if (op.retry(err)) {
              return;
            }
            if (err) {
              arguments[0] = op.mainError();
            }
            callback.apply(this, arguments);
          });
          op.attempt(function() {
            original2.apply(obj, args);
          });
        }.bind(obj, original);
        obj[method].options = options;
      }
    };
  }
});

// ../../../node_modules/retry/index.js
var require_retry2 = __commonJS({
  "../../../node_modules/retry/index.js"(exports2, module2) {
    module2.exports = require_retry();
  }
});

// ../../../node_modules/signal-exit/signals.js
var require_signals = __commonJS({
  "../../../node_modules/signal-exit/signals.js"(exports2, module2) {
    module2.exports = [
      "SIGABRT",
      "SIGALRM",
      "SIGHUP",
      "SIGINT",
      "SIGTERM"
    ];
    if (process.platform !== "win32") {
      module2.exports.push(
        "SIGVTALRM",
        "SIGXCPU",
        "SIGXFSZ",
        "SIGUSR2",
        "SIGTRAP",
        "SIGSYS",
        "SIGQUIT",
        "SIGIOT"
        // should detect profiler and enable/disable accordingly.
        // see #21
        // 'SIGPROF'
      );
    }
    if (process.platform === "linux") {
      module2.exports.push(
        "SIGIO",
        "SIGPOLL",
        "SIGPWR",
        "SIGSTKFLT",
        "SIGUNUSED"
      );
    }
  }
});

// ../../../node_modules/signal-exit/index.js
var require_signal_exit = __commonJS({
  "../../../node_modules/signal-exit/index.js"(exports2, module2) {
    var process2 = global.process;
    var processOk = function(process3) {
      return process3 && typeof process3 === "object" && typeof process3.removeListener === "function" && typeof process3.emit === "function" && typeof process3.reallyExit === "function" && typeof process3.listeners === "function" && typeof process3.kill === "function" && typeof process3.pid === "number" && typeof process3.on === "function";
    };
    if (!processOk(process2)) {
      module2.exports = function() {
        return function() {
        };
      };
    } else {
      assert = require("assert");
      signals = require_signals();
      isWin = /^win/i.test(process2.platform);
      EE = require("events");
      if (typeof EE !== "function") {
        EE = EE.EventEmitter;
      }
      if (process2.__signal_exit_emitter__) {
        emitter = process2.__signal_exit_emitter__;
      } else {
        emitter = process2.__signal_exit_emitter__ = new EE();
        emitter.count = 0;
        emitter.emitted = {};
      }
      if (!emitter.infinite) {
        emitter.setMaxListeners(Infinity);
        emitter.infinite = true;
      }
      module2.exports = function(cb, opts) {
        if (!processOk(global.process)) {
          return function() {
          };
        }
        assert.equal(typeof cb, "function", "a callback must be provided for exit handler");
        if (loaded === false) {
          load();
        }
        var ev = "exit";
        if (opts && opts.alwaysLast) {
          ev = "afterexit";
        }
        var remove = function() {
          emitter.removeListener(ev, cb);
          if (emitter.listeners("exit").length === 0 && emitter.listeners("afterexit").length === 0) {
            unload();
          }
        };
        emitter.on(ev, cb);
        return remove;
      };
      unload = function unload2() {
        if (!loaded || !processOk(global.process)) {
          return;
        }
        loaded = false;
        signals.forEach(function(sig) {
          try {
            process2.removeListener(sig, sigListeners[sig]);
          } catch (er) {
          }
        });
        process2.emit = originalProcessEmit;
        process2.reallyExit = originalProcessReallyExit;
        emitter.count -= 1;
      };
      module2.exports.unload = unload;
      emit = function emit2(event, code, signal) {
        if (emitter.emitted[event]) {
          return;
        }
        emitter.emitted[event] = true;
        emitter.emit(event, code, signal);
      };
      sigListeners = {};
      signals.forEach(function(sig) {
        sigListeners[sig] = function listener() {
          if (!processOk(global.process)) {
            return;
          }
          var listeners = process2.listeners(sig);
          if (listeners.length === emitter.count) {
            unload();
            emit("exit", null, sig);
            emit("afterexit", null, sig);
            if (isWin && sig === "SIGHUP") {
              sig = "SIGINT";
            }
            process2.kill(process2.pid, sig);
          }
        };
      });
      module2.exports.signals = function() {
        return signals;
      };
      loaded = false;
      load = function load2() {
        if (loaded || !processOk(global.process)) {
          return;
        }
        loaded = true;
        emitter.count += 1;
        signals = signals.filter(function(sig) {
          try {
            process2.on(sig, sigListeners[sig]);
            return true;
          } catch (er) {
            return false;
          }
        });
        process2.emit = processEmit;
        process2.reallyExit = processReallyExit;
      };
      module2.exports.load = load;
      originalProcessReallyExit = process2.reallyExit;
      processReallyExit = function processReallyExit2(code) {
        if (!processOk(global.process)) {
          return;
        }
        process2.exitCode = code || /* istanbul ignore next */
        0;
        emit("exit", process2.exitCode, null);
        emit("afterexit", process2.exitCode, null);
        originalProcessReallyExit.call(process2, process2.exitCode);
      };
      originalProcessEmit = process2.emit;
      processEmit = function processEmit2(ev, arg) {
        if (ev === "exit" && processOk(global.process)) {
          if (arg !== void 0) {
            process2.exitCode = arg;
          }
          var ret = originalProcessEmit.apply(this, arguments);
          emit("exit", process2.exitCode, null);
          emit("afterexit", process2.exitCode, null);
          return ret;
        } else {
          return originalProcessEmit.apply(this, arguments);
        }
      };
    }
    var assert;
    var signals;
    var isWin;
    var EE;
    var emitter;
    var unload;
    var emit;
    var sigListeners;
    var loaded;
    var load;
    var originalProcessReallyExit;
    var processReallyExit;
    var originalProcessEmit;
    var processEmit;
  }
});

// ../../../node_modules/proper-lockfile/lib/mtime-precision.js
var require_mtime_precision = __commonJS({
  "../../../node_modules/proper-lockfile/lib/mtime-precision.js"(exports2, module2) {
    "use strict";
    var cacheSymbol = /* @__PURE__ */ Symbol();
    function probe(file, fs2, callback) {
      const cachedPrecision = fs2[cacheSymbol];
      if (cachedPrecision) {
        return fs2.stat(file, (err, stat) => {
          if (err) {
            return callback(err);
          }
          callback(null, stat.mtime, cachedPrecision);
        });
      }
      const mtime = new Date(Math.ceil(Date.now() / 1e3) * 1e3 + 5);
      fs2.utimes(file, mtime, mtime, (err) => {
        if (err) {
          return callback(err);
        }
        fs2.stat(file, (err2, stat) => {
          if (err2) {
            return callback(err2);
          }
          const precision = stat.mtime.getTime() % 1e3 === 0 ? "s" : "ms";
          Object.defineProperty(fs2, cacheSymbol, { value: precision });
          callback(null, stat.mtime, precision);
        });
      });
    }
    function getMtime(precision) {
      let now = Date.now();
      if (precision === "s") {
        now = Math.ceil(now / 1e3) * 1e3;
      }
      return new Date(now);
    }
    module2.exports.probe = probe;
    module2.exports.getMtime = getMtime;
  }
});

// ../../../node_modules/proper-lockfile/lib/lockfile.js
var require_lockfile = __commonJS({
  "../../../node_modules/proper-lockfile/lib/lockfile.js"(exports2, module2) {
    "use strict";
    var path2 = require("path");
    var fs2 = require_graceful_fs();
    var retry = require_retry2();
    var onExit = require_signal_exit();
    var mtimePrecision = require_mtime_precision();
    var locks = {};
    function getLockFile(file, options) {
      return options.lockfilePath || `${file}.lock`;
    }
    function resolveCanonicalPath(file, options, callback) {
      if (!options.realpath) {
        return callback(null, path2.resolve(file));
      }
      options.fs.realpath(file, callback);
    }
    function acquireLock(file, options, callback) {
      const lockfilePath = getLockFile(file, options);
      options.fs.mkdir(lockfilePath, (err) => {
        if (!err) {
          return mtimePrecision.probe(lockfilePath, options.fs, (err2, mtime, mtimePrecision2) => {
            if (err2) {
              options.fs.rmdir(lockfilePath, () => {
              });
              return callback(err2);
            }
            callback(null, mtime, mtimePrecision2);
          });
        }
        if (err.code !== "EEXIST") {
          return callback(err);
        }
        if (options.stale <= 0) {
          return callback(Object.assign(new Error("Lock file is already being held"), { code: "ELOCKED", file }));
        }
        options.fs.stat(lockfilePath, (err2, stat) => {
          if (err2) {
            if (err2.code === "ENOENT") {
              return acquireLock(file, { ...options, stale: 0 }, callback);
            }
            return callback(err2);
          }
          if (!isLockStale(stat, options)) {
            return callback(Object.assign(new Error("Lock file is already being held"), { code: "ELOCKED", file }));
          }
          removeLock(file, options, (err3) => {
            if (err3) {
              return callback(err3);
            }
            acquireLock(file, { ...options, stale: 0 }, callback);
          });
        });
      });
    }
    function isLockStale(stat, options) {
      return stat.mtime.getTime() < Date.now() - options.stale;
    }
    function removeLock(file, options, callback) {
      options.fs.rmdir(getLockFile(file, options), (err) => {
        if (err && err.code !== "ENOENT") {
          return callback(err);
        }
        callback();
      });
    }
    function updateLock(file, options) {
      const lock2 = locks[file];
      if (lock2.updateTimeout) {
        return;
      }
      lock2.updateDelay = lock2.updateDelay || options.update;
      lock2.updateTimeout = setTimeout(() => {
        lock2.updateTimeout = null;
        options.fs.stat(lock2.lockfilePath, (err, stat) => {
          const isOverThreshold = lock2.lastUpdate + options.stale < Date.now();
          if (err) {
            if (err.code === "ENOENT" || isOverThreshold) {
              return setLockAsCompromised(file, lock2, Object.assign(err, { code: "ECOMPROMISED" }));
            }
            lock2.updateDelay = 1e3;
            return updateLock(file, options);
          }
          const isMtimeOurs = lock2.mtime.getTime() === stat.mtime.getTime();
          if (!isMtimeOurs) {
            return setLockAsCompromised(
              file,
              lock2,
              Object.assign(
                new Error("Unable to update lock within the stale threshold"),
                { code: "ECOMPROMISED" }
              )
            );
          }
          const mtime = mtimePrecision.getMtime(lock2.mtimePrecision);
          options.fs.utimes(lock2.lockfilePath, mtime, mtime, (err2) => {
            const isOverThreshold2 = lock2.lastUpdate + options.stale < Date.now();
            if (lock2.released) {
              return;
            }
            if (err2) {
              if (err2.code === "ENOENT" || isOverThreshold2) {
                return setLockAsCompromised(file, lock2, Object.assign(err2, { code: "ECOMPROMISED" }));
              }
              lock2.updateDelay = 1e3;
              return updateLock(file, options);
            }
            lock2.mtime = mtime;
            lock2.lastUpdate = Date.now();
            lock2.updateDelay = null;
            updateLock(file, options);
          });
        });
      }, lock2.updateDelay);
      if (lock2.updateTimeout.unref) {
        lock2.updateTimeout.unref();
      }
    }
    function setLockAsCompromised(file, lock2, err) {
      lock2.released = true;
      if (lock2.updateTimeout) {
        clearTimeout(lock2.updateTimeout);
      }
      if (locks[file] === lock2) {
        delete locks[file];
      }
      lock2.options.onCompromised(err);
    }
    function lock(file, options, callback) {
      options = {
        stale: 1e4,
        update: null,
        realpath: true,
        retries: 0,
        fs: fs2,
        onCompromised: (err) => {
          throw err;
        },
        ...options
      };
      options.retries = options.retries || 0;
      options.retries = typeof options.retries === "number" ? { retries: options.retries } : options.retries;
      options.stale = Math.max(options.stale || 0, 2e3);
      options.update = options.update == null ? options.stale / 2 : options.update || 0;
      options.update = Math.max(Math.min(options.update, options.stale / 2), 1e3);
      resolveCanonicalPath(file, options, (err, file2) => {
        if (err) {
          return callback(err);
        }
        const operation = retry.operation(options.retries);
        operation.attempt(() => {
          acquireLock(file2, options, (err2, mtime, mtimePrecision2) => {
            if (operation.retry(err2)) {
              return;
            }
            if (err2) {
              return callback(operation.mainError());
            }
            const lock2 = locks[file2] = {
              lockfilePath: getLockFile(file2, options),
              mtime,
              mtimePrecision: mtimePrecision2,
              options,
              lastUpdate: Date.now()
            };
            updateLock(file2, options);
            callback(null, (releasedCallback) => {
              if (lock2.released) {
                return releasedCallback && releasedCallback(Object.assign(new Error("Lock is already released"), { code: "ERELEASED" }));
              }
              unlock(file2, { ...options, realpath: false }, releasedCallback);
            });
          });
        });
      });
    }
    function unlock(file, options, callback) {
      options = {
        fs: fs2,
        realpath: true,
        ...options
      };
      resolveCanonicalPath(file, options, (err, file2) => {
        if (err) {
          return callback(err);
        }
        const lock2 = locks[file2];
        if (!lock2) {
          return callback(Object.assign(new Error("Lock is not acquired/owned by you"), { code: "ENOTACQUIRED" }));
        }
        lock2.updateTimeout && clearTimeout(lock2.updateTimeout);
        lock2.released = true;
        delete locks[file2];
        removeLock(file2, options, callback);
      });
    }
    function check(file, options, callback) {
      options = {
        stale: 1e4,
        realpath: true,
        fs: fs2,
        ...options
      };
      options.stale = Math.max(options.stale || 0, 2e3);
      resolveCanonicalPath(file, options, (err, file2) => {
        if (err) {
          return callback(err);
        }
        options.fs.stat(getLockFile(file2, options), (err2, stat) => {
          if (err2) {
            return err2.code === "ENOENT" ? callback(null, false) : callback(err2);
          }
          return callback(null, !isLockStale(stat, options));
        });
      });
    }
    function getLocks() {
      return locks;
    }
    onExit(() => {
      for (const file in locks) {
        const options = locks[file].options;
        try {
          options.fs.rmdirSync(getLockFile(file, options));
        } catch (e) {
        }
      }
    });
    module2.exports.lock = lock;
    module2.exports.unlock = unlock;
    module2.exports.check = check;
    module2.exports.getLocks = getLocks;
  }
});

// ../../../node_modules/proper-lockfile/lib/adapter.js
var require_adapter = __commonJS({
  "../../../node_modules/proper-lockfile/lib/adapter.js"(exports2, module2) {
    "use strict";
    var fs2 = require_graceful_fs();
    function createSyncFs(fs3) {
      const methods = ["mkdir", "realpath", "stat", "rmdir", "utimes"];
      const newFs = { ...fs3 };
      methods.forEach((method) => {
        newFs[method] = (...args) => {
          const callback = args.pop();
          let ret;
          try {
            ret = fs3[`${method}Sync`](...args);
          } catch (err) {
            return callback(err);
          }
          callback(null, ret);
        };
      });
      return newFs;
    }
    function toPromise(method) {
      return (...args) => new Promise((resolve, reject) => {
        args.push((err, result) => {
          if (err) {
            reject(err);
          } else {
            resolve(result);
          }
        });
        method(...args);
      });
    }
    function toSync(method) {
      return (...args) => {
        let err;
        let result;
        args.push((_err, _result) => {
          err = _err;
          result = _result;
        });
        method(...args);
        if (err) {
          throw err;
        }
        return result;
      };
    }
    function toSyncOptions(options) {
      options = { ...options };
      options.fs = createSyncFs(options.fs || fs2);
      if (typeof options.retries === "number" && options.retries > 0 || options.retries && typeof options.retries.retries === "number" && options.retries.retries > 0) {
        throw Object.assign(new Error("Cannot use retries with the sync api"), { code: "ESYNC" });
      }
      return options;
    }
    module2.exports = {
      toPromise,
      toSync,
      toSyncOptions
    };
  }
});

// ../../../node_modules/proper-lockfile/index.js
var require_proper_lockfile = __commonJS({
  "../../../node_modules/proper-lockfile/index.js"(exports2, module2) {
    "use strict";
    var lockfile = require_lockfile();
    var { toPromise, toSync, toSyncOptions } = require_adapter();
    async function lock(file, options) {
      const release = await toPromise(lockfile.lock)(file, options);
      return toPromise(release);
    }
    function lockSync(file, options) {
      const release = toSync(lockfile.lock)(file, toSyncOptions(options));
      return toSync(release);
    }
    function unlock(file, options) {
      return toPromise(lockfile.unlock)(file, options);
    }
    function unlockSync(file, options) {
      return toSync(lockfile.unlock)(file, toSyncOptions(options));
    }
    function check(file, options) {
      return toPromise(lockfile.check)(file, options);
    }
    function checkSync(file, options) {
      return toSync(lockfile.check)(file, toSyncOptions(options));
    }
    module2.exports = lock;
    module2.exports.lock = lock;
    module2.exports.unlock = unlock;
    module2.exports.lockSync = lockSync;
    module2.exports.unlockSync = unlockSync;
    module2.exports.check = check;
    module2.exports.checkSync = checkSync;
  }
});

// mac-lock.cjs
var require_mac_lock = __commonJS({
  "mac-lock.cjs"(exports2, module2) {
    "use strict";
    var fs2 = require("node:fs/promises");
    var path2 = require("node:path");
    var lockfile = require_proper_lockfile();
    var STALE_MS = 6e4;
    var UPDATE_MS = 1e4;
    var NAMES = /* @__PURE__ */ new Set(["update.lock", ".request.lock", ".launch.lock"]);
    async function acquireLock(root, name) {
      if (!path2.isAbsolute(root) || !NAMES.has(name)) throw new Error("Invalid installation lock.");
      const absolute = path2.resolve(root), real = await fs2.realpath(root);
      if (process.platform === "win32" ? real.toLowerCase() !== absolute.toLowerCase() : real !== absolute) throw new Error("Installation locks require a canonical directory.");
      const file = path2.join(absolute, name);
      try {
        const stat = await fs2.lstat(file);
        if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("Another operation or an invalid installation lock needs attention.");
      } catch (error) {
        if (error.code !== "ENOENT") throw error;
      }
      try {
        return await lockfile.lock(file, { lockfilePath: file, realpath: false, stale: STALE_MS, update: UPDATE_MS, retries: 0 });
      } catch {
        throw new Error("Another installer operation is active. Try again after it finishes.");
      }
    }
    async function withLock2(root, name, operation) {
      const release = await acquireLock(root, name);
      try {
        return await operation();
      } finally {
        await release();
      }
    }
    module2.exports = { acquireLock, withLock: withLock2, STALE_MS, UPDATE_MS };
  }
});

// mac-archive.cjs
var require_mac_archive = __commonJS({
  "mac-archive.cjs"(exports2, module2) {
    "use strict";
    var fs2 = require("node:fs/promises");
    var { createReadStream } = require("node:fs");
    var path2 = require("node:path");
    var { createHash, randomUUID } = require("node:crypto");
    var { createGunzip } = require("node:zlib");
    var { Transform } = require("node:stream");
    var tar = require_commonjs7();
    var { releaseVersion: releaseVersion2, selectArtifact: selectArtifact2 } = require_channel();
    var { acquireLock } = require_mac_lock();
    var MANIFEST2 = "design-editor-build.json";
    var MAX_FILES = 3e4;
    var MAX_BYTES = 4 * 1024 ** 3;
    var MAX_MANIFEST2 = 8 * 1024 ** 2;
    var SOURCE2 = Object.freeze({ repository: "pavanxs/design-editor-downloads", channel: "beta" });
    var OWNER = "Design Editor installation v1";
    function keys(value, expected) {
      if (!value || typeof value !== "object" || Array.isArray(value) || Object.keys(value).sort().join("\0") !== [...expected].sort().join("\0")) throw new Error("Unexpected native manifest fields.");
    }
    function name(value) {
      if (typeof value !== "string" || !value || value.length > 400 || /[^\x20-\x7e]|[\\:<>"|?*]/.test(value) || value.startsWith("/") || value.endsWith("/")) throw new Error("Unsafe native archive path.");
      const parts = value.split("/");
      if (parts.length > 40 || parts.some((part) => !part || [".", ".."].includes(part) || /[. ]$/.test(part) || /^(?:\.git|\.github|\.DS_Store|\.env(?:\..*)?|\.npmrc|\.pypirc)$/i.test(part))) throw new Error("Unsafe native archive path.");
      return value;
    }
    function targetName(value) {
      if (typeof value !== "string" || !value || value.length > 400 || /[^\x20-\x7e]|[\\:<>"|?*]/.test(value) || value.startsWith("/") || value.endsWith("/")) throw new Error("Unsafe native framework link.");
      if (value.split("/").some((part) => !part || /[. ]$/.test(part) && ![".", ".."].includes(part))) throw new Error("Unsafe native framework link.");
      return value;
    }
    function validateManifest2(value, version, arch) {
      keys(value, ["schemaVersion", "product", "version", "platform", "arch", "electron", "executable", "asar", "files"]);
      releaseVersion2(version, "beta");
      if (!["x64", "arm64"].includes(arch) || value.schemaVersion !== 1 || value.product !== "design-editor" || value.version !== version || value.platform !== "darwin" || value.arch !== arch || typeof value.electron !== "string" || value.electron.length > 50 || value.electron.trim() !== value.electron || !/^\d+\.\d+\.\d+$/.test(value.electron)) throw new Error("Native manifest does not match this Mac release.");
      const executable = name(value.executable), asar = name(value.asar);
      const match = /^app\/([^/]+\.app)\/Contents\/MacOS\/[^/]+$/.exec(executable);
      if (!match || asar !== `app/${match[1]}/Contents/Resources/app.asar`) throw new Error("The Mac application layout is invalid.");
      if (!Array.isArray(value.files) || !value.files.length || value.files.length > MAX_FILES) throw new Error("Native file budget exceeded.");
      const entries = /* @__PURE__ */ new Map(), folded = /* @__PURE__ */ new Map(), directories = /* @__PURE__ */ new Set();
      let total = 0;
      for (const item of value.files) {
        keys(item, item?.type === "file" ? ["path", "type", "bytes", "sha256", "mode"] : ["path", "type", "target"]);
        const file = name(item.path);
        if (!file.startsWith("app/") || entries.has(file)) throw new Error("Duplicate or unrelated native archive entry.");
        if (item.type === "file") {
          if (!Number.isSafeInteger(item.bytes) || item.bytes < 0 || item.bytes > 2 ** 31 - 1 || typeof item.sha256 !== "string" || item.sha256.length !== 64 || !/^[a-f0-9]{64}$/.test(item.sha256) || !Number.isInteger(item.mode) || item.mode < 0 || item.mode > 511) throw new Error("Invalid native file metadata.");
          total += item.bytes;
          if (total > MAX_BYTES) throw new Error("Native expanded-size budget exceeded.");
        } else if (item.type === "link") targetName(item.target);
        else throw new Error("Only regular files and internal framework links are supported.");
        entries.set(file, Object.freeze({ ...item }));
        for (let current = file; current !== "."; current = path2.posix.dirname(current)) {
          const key = current.toUpperCase(), prior = folded.get(key);
          if (prior && prior !== current) throw new Error("Case-colliding native archive paths.");
          folded.set(key, current);
          if (current !== file) directories.add(current);
        }
      }
      for (const file of directories) if (entries.has(file)) throw new Error("A file or link cannot also be an archive parent.");
      if (entries.get(executable)?.type !== "file" || !(entries.get(executable).mode & 73) || entries.get(asar)?.type !== "file") throw new Error("The native executable or application payload is absent.");
      function resolveLink(file) {
        let current = file;
        const visited = /* @__PURE__ */ new Set();
        for (let count = 0; count <= 40; count++) {
          if (visited.has(current)) throw new Error("Cyclic framework link.");
          visited.add(current);
          const parts = current.split("/");
          let replaced = false;
          for (let i = 1; i <= parts.length; i++) {
            const prefix = parts.slice(0, i).join("/"), entry = entries.get(prefix);
            if (entry?.type === "link") {
              current = path2.posix.normalize(path2.posix.join(path2.posix.dirname(prefix), entry.target, ...parts.slice(i)));
              if (!current.startsWith("app/")) throw new Error("A framework link leaves the application.");
              replaced = true;
              break;
            }
          }
          if (!replaced) {
            if (!entries.has(current) && !directories.has(current)) throw new Error("Dangling framework link.");
            return current;
          }
        }
        throw new Error("Framework link depth exceeded.");
      }
      for (const [file, entry] of entries) if (entry.type === "link") resolveLink(file);
      return { manifest: Object.freeze({ ...value, files: Object.freeze([...entries.values()]) }), entries, directories, expandedBytes: total };
    }
    async function digest(file) {
      const hash = createHash("sha256");
      for await (const data of createReadStream(file)) hash.update(data);
      return hash.digest("hex");
    }
    async function plainPath2(file) {
      const absolute = path2.resolve(file);
      for (let cursor = absolute; ; cursor = path2.dirname(cursor)) {
        try {
          if ((await fs2.lstat(cursor)).isSymbolicLink()) throw new Error("Installation paths must not pass through a link.");
        } catch (error) {
          if (error.code !== "ENOENT") throw error;
        }
        if (cursor === path2.dirname(cursor)) break;
      }
      return absolute;
    }
    async function plainDirectory2(directory) {
      const absolute = await plainPath2(directory);
      await fs2.mkdir(absolute, { recursive: true, mode: 448 });
      const info = await fs2.lstat(absolute), real = await fs2.realpath(absolute);
      const same = process.platform === "win32" ? real.toLowerCase() === absolute.toLowerCase() : real === absolute;
      if (!info.isDirectory() || info.isSymbolicLink() || !same) throw new Error("Use an ordinary canonical installation directory.");
      return absolute;
    }
    async function readBounded2(file, maximum) {
      await plainPath2(file);
      const stat = await fs2.lstat(file);
      if (!stat.isFile() || stat.isSymbolicLink() || stat.nlink !== 1 || stat.size > maximum) throw new Error("Invalid installation record.");
      const bytes = await fs2.readFile(file);
      if (bytes.length !== stat.size || bytes.length > maximum) throw new Error("Installation record changed while reading.");
      return bytes;
    }
    async function initializeRoot2(root) {
      if (typeof root !== "string" || !path2.isAbsolute(root)) throw new Error("Use an absolute installation directory.");
      root = await plainPath2(root);
      const marker = path2.join(root, ".design-editor-root");
      try {
        const stat2 = await fs2.lstat(root);
        if (!stat2.isDirectory()) throw new Error("Use an ordinary installation directory.");
        try {
          await fs2.lstat(marker);
        } catch (error) {
          if (error.code !== "ENOENT") throw error;
          if ((await fs2.readdir(root)).length) throw new Error("The destination is not an editor-owned installation.");
        }
      } catch (error) {
        if (error.code !== "ENOENT") throw error;
      }
      root = await plainDirectory2(root);
      const stat = await fs2.lstat(root);
      if (process.platform !== "win32" && (stat.uid !== process.getuid() || stat.mode & 18)) throw new Error("The installation directory must be owned by you and not writable by other users.");
      try {
        await fs2.writeFile(marker, OWNER, { flag: "wx", mode: 384 });
      } catch (error) {
        if (error.code !== "EEXIST") throw error;
      }
      if ((await readBounded2(marker, 128)).toString("utf8") !== OWNER) throw new Error("Invalid installation ownership marker.");
      return root;
    }
    async function inspectArchive2(archive, channel, arch) {
      const selected = selectArtifact2(channel, { platform: "darwin", arch }, SOURCE2);
      if (!selected || !selected.filename.endsWith(".tar.gz")) throw new Error("This channel has no native tar.gz release for this Mac.");
      await plainPath2(archive);
      const stat = await fs2.lstat(archive);
      if (!stat.isFile() || stat.isSymbolicLink() || stat.size !== selected.bytes || await digest(archive) !== selected.sha256) throw new Error("Native download checksum or size did not match.");
      const observed = /* @__PURE__ */ new Map();
      let manifestText = null, expanded = 0, fileBytes = 0, count = 0;
      await new Promise((resolve, reject) => {
        let finished = false;
        const input = createReadStream(archive), unzip = createGunzip();
        const cap = new Transform({ transform(chunk, _encoding, callback) {
          expanded += chunk.length;
          callback(expanded > MAX_BYTES + MAX_MANIFEST2 + 64 * 1024 ** 2 ? new Error("Expanded archive stream exceeds the limit.") : null, chunk);
        } });
        const parser = new tar.Parser({ strict: true, maxMetaEntrySize: 64 * 1024, maxDepth: 40 });
        const timer = setTimeout(() => fail(new Error("Native archive verification timed out.")), 12e4);
        function fail(error) {
          if (finished) return;
          finished = true;
          clearTimeout(timer);
          input.destroy();
          unzip.destroy();
          cap.destroy();
          parser.abort(error);
          reject(new Error("Native archive verification failed: " + error.message));
        }
        for (const stream of [input, unzip, cap, parser]) stream.on("error", fail);
        parser.on("entry", (entry) => {
          try {
            if (++count > MAX_FILES * 3) throw new Error("Archive entry budget exceeded.");
            const file = name(entry.type === "Directory" ? entry.path.replace(/\/$/, "") : entry.path);
            if (observed.has(file)) throw new Error("Duplicate archive member.");
            if (!["File", "Directory", "SymbolicLink"].includes(entry.type)) throw new Error("Unsupported archive member type.");
            if (!Number.isSafeInteger(entry.size) || entry.size < 0 || entry.size > 2 ** 31 - 1) throw new Error("Invalid archive entry size.");
            if (entry.type !== "File" && entry.size !== 0) throw new Error("A directory or link must not carry file data.");
            fileBytes += entry.size;
            if (fileBytes > MAX_BYTES + MAX_MANIFEST2) throw new Error("Declared archive size exceeds the limit.");
            if (file === MANIFEST2 && (entry.type !== "File" || entry.size > MAX_MANIFEST2)) throw new Error("Invalid native manifest entry.");
            const row = { type: entry.type, bytes: entry.size, target: entry.linkpath };
            observed.set(file, row);
            const hash = createHash("sha256"), chunks = [];
            let size = 0;
            entry.on("data", (chunk) => {
              size += chunk.length;
              hash.update(chunk);
              if (file === MANIFEST2) chunks.push(chunk);
            });
            entry.on("end", () => {
              if (size !== entry.size) {
                fail(new Error("Truncated archive member."));
                return;
              }
              row.sha256 = hash.digest("hex");
              if (file === MANIFEST2) manifestText = Buffer.concat(chunks).toString("utf8");
            });
            entry.on("error", fail);
            entry.resume();
          } catch (error) {
            fail(error);
          }
        });
        parser.on("end", () => {
          if (!finished) {
            finished = true;
            clearTimeout(timer);
            resolve();
          }
        });
        input.pipe(unzip).pipe(cap).pipe(parser);
      });
      let value;
      try {
        value = JSON.parse(manifestText);
      } catch {
        throw new Error("Native manifest is missing or invalid JSON.");
      }
      const checked = validateManifest2(value, channel.version, arch);
      for (const [file, row] of observed) {
        if (file === MANIFEST2) continue;
        if (row.type === "Directory") {
          if (!checked.directories.has(file)) throw new Error("Undeclared archive directory.");
          continue;
        }
        const item = checked.entries.get(file);
        if (!item) throw new Error("Undeclared archive resource.");
        if (item.type === "file" ? row.type !== "File" || row.bytes !== item.bytes || row.sha256 !== item.sha256 : row.type !== "SymbolicLink" || row.target !== item.target || row.bytes !== 0) throw new Error("An archive resource does not match its manifest.");
      }
      if ([...checked.entries.keys()].some((file) => !observed.has(file))) throw new Error("A declared native resource is missing.");
      return { ...checked, artifact: selected, manifestSha256: observed.get(MANIFEST2).sha256 };
    }
    async function verifyTree2(directory, checked) {
      directory = await plainPath2(directory);
      if (!(await fs2.lstat(directory)).isDirectory()) throw new Error("Invalid version directory.");
      async function walk(relative = "") {
        for (const entry of await fs2.readdir(path2.join(directory, relative), { withFileTypes: true })) {
          const name2 = relative ? `${relative}/${entry.name}` : entry.name;
          if (!relative && [MANIFEST2, ".archive-sha256"].includes(name2)) {
            await readBounded2(path2.join(directory, name2), name2 === MANIFEST2 ? MAX_MANIFEST2 : 128);
            continue;
          }
          if (entry.isDirectory()) {
            if (!checked.directories.has(name2)) throw new Error("Undeclared installed directory.");
            await plainPath2(path2.join(directory, name2));
            await walk(name2);
          } else {
            if (checked.directories.has(name2)) throw new Error("Linked or invalid installed directory.");
            if (!checked.entries.has(name2)) throw new Error("Undeclared installed resource.");
          }
        }
      }
      await walk();
      if (checked.manifestSha256 && createHash("sha256").update(await readBounded2(path2.join(directory, MANIFEST2), MAX_MANIFEST2)).digest("hex") !== checked.manifestSha256) throw new Error("Installed manifest changed.");
      for (const item of checked.manifest.files) {
        const file = path2.join(directory, item.path), stat = await fs2.lstat(file);
        if (item.type === "file") {
          await plainPath2(file);
          if (!stat.isFile() || stat.isSymbolicLink() || stat.nlink !== 1 || stat.size !== item.bytes || await digest(file) !== item.sha256) throw new Error("Installed file verification failed.");
          if (process.platform !== "win32" && (stat.mode & 4095) !== (item.mode & 493)) throw new Error("Installed file permissions changed.");
        } else {
          if (!stat.isSymbolicLink() || await fs2.readlink(file) !== item.target) throw new Error("Installed framework link changed.");
          const actual = await fs2.realpath(file);
          if (!actual.startsWith(directory + path2.sep)) throw new Error("Installed framework link leaves its version directory.");
        }
      }
      const executables = [checked.manifest.executable, ...checked.manifest.files.filter((item) => item.path.endsWith("/agent-runtime/runtime/node")).map((item) => item.path)];
      for (const executable of executables) {
        const handle = await fs2.open(path2.join(directory, executable), "r");
        const header = Buffer.alloc(8);
        let bytesRead;
        try {
          ({ bytesRead } = await handle.read(header, 0, 8, 0));
        } finally {
          await handle.close();
        }
        if (bytesRead !== 8 || header.readUInt32LE(0) !== 4277009103 || header.readUInt32LE(4) !== (checked.manifest.arch === "arm64" ? 16777228 : 16777223)) throw new Error("Native executable does not match the Mac architecture.");
      }
    }
    async function installArchive2(archive, channel, root, arch) {
      root = await initializeRoot2(root);
      const token = randomUUID(), releaseLock = await acquireLock(root, "update.lock");
      let temporary;
      try {
        const checked = await inspectArchive2(archive, channel, arch);
        const versions = await plainDirectory2(path2.join(root, "versions")), relative = `versions/${channel.version}-darwin-${arch}`, destination = path2.join(root, relative);
        let exists = false;
        try {
          const stat = await fs2.lstat(destination);
          if (!stat.isDirectory() || stat.isSymbolicLink()) throw new Error("Existing version path is invalid.");
          exists = true;
        } catch (error) {
          if (error.code !== "ENOENT") throw error;
        }
        if (exists) {
          if ((await readBounded2(path2.join(destination, ".archive-sha256"), 128)).toString("utf8").trim() !== checked.artifact.sha256) throw new Error("This version already exists with different archive bytes.");
          await verifyTree2(destination, checked);
        } else {
          temporary = await fs2.mkdtemp(path2.join(versions, ".install-"));
          await fs2.chmod(temporary, 448);
          await tar.x({
            file: archive,
            cwd: temporary,
            strict: true,
            preservePaths: false,
            noMtime: true,
            noChmod: true,
            maxDepth: 40,
            maxMetaEntrySize: 64 * 1024,
            maxDecompressionRatio: 1e3,
            filter: (file, entry) => {
              if (entry.type === "SymbolicLink") return false;
              const expected = checked.entries.get(file);
              if (entry.type === "File" && file === MANIFEST2) {
                if (entry.size > MAX_MANIFEST2) throw new Error("Manifest changed during extraction.");
                return true;
              }
              if (entry.type === "Directory" && checked.directories.has(file.replace(/\/$/, "")) && entry.size === 0) return true;
              if (entry.type === "File" && expected?.type === "file" && entry.size === expected.bytes) return true;
              throw new Error("Archive changed during extraction.");
            }
          });
          for (const item of checked.manifest.files) if (item.type === "file") await fs2.chmod(path2.join(temporary, item.path), item.mode & 493);
          for (const item of checked.manifest.files) if (item.type === "link") await fs2.symlink(item.target, path2.join(temporary, item.path));
          await verifyTree2(temporary, checked);
          await fs2.writeFile(path2.join(temporary, ".archive-sha256"), checked.artifact.sha256 + "\n", { flag: "wx", mode: 384 });
          await fs2.rename(temporary, destination);
          temporary = null;
        }
        if (await digest(archive) !== checked.artifact.sha256) throw new Error("Archive changed during installation.");
        const current = { schemaVersion: 1, product: "design-editor", version: channel.version, platform: "darwin", arch, directory: relative, executable: checked.manifest.executable, asar: checked.manifest.asar, archiveSha256: checked.artifact.sha256 };
        const pointer = path2.join(root, "current.json");
        try {
          const stat = await fs2.lstat(pointer);
          if (!stat.isFile() || stat.isSymbolicLink()) throw new Error("Current installation record is not a regular file.");
        } catch (error) {
          if (error.code !== "ENOENT") throw error;
        }
        const next = path2.join(root, `.current-${token}.json`);
        try {
          const writer = await fs2.open(next, "wx", 384);
          try {
            await writer.writeFile(JSON.stringify(current) + "\n");
            await writer.sync();
          } finally {
            await writer.close();
          }
          await fs2.rename(next, pointer);
        } finally {
          await fs2.rm(next, { force: true });
        }
        return current;
      } finally {
        try {
          if (temporary) await fs2.rm(temporary, { recursive: true, force: true, maxRetries: 3 });
        } finally {
          await releaseLock();
        }
      }
    }
    module2.exports = { validateManifest: validateManifest2, inspectArchive: inspectArchive2, installArchive: installArchive2, verifyTree: verifyTree2, digest, plainPath: plainPath2, plainDirectory: plainDirectory2, readBounded: readBounded2, initializeRoot: initializeRoot2, MANIFEST: MANIFEST2, MAX_FILES, MAX_BYTES, MAX_MANIFEST: MAX_MANIFEST2, SOURCE: SOURCE2 };
  }
});

// mac-network.cjs
var require_mac_network = __commonJS({
  "mac-network.cjs"(exports2, module2) {
    "use strict";
    var fs2 = require("node:fs/promises");
    var path2 = require("node:path");
    var { createHash } = require("node:crypto");
    var { parseChannel, selectArtifact: selectArtifact2, MAX_CHANNEL_BYTES } = require_channel();
    var { plainPath: plainPath2, SOURCE: SOURCE2 } = require_mac_archive();
    var CHANNEL_URL = "https://raw.githubusercontent.com/pavanxs/design-editor-downloads/main/channels/beta.json";
    var DOWNLOAD_TIMEOUT = 3e5;
    function redirectAddress(location, previous) {
      const url = new URL(location, previous);
      if (url.protocol !== "https:" || url.username || url.password || url.port || url.hash || !["release-assets.githubusercontent.com", "objects.githubusercontent.com"].includes(url.hostname)) {
        throw new Error("Unapproved release redirect.");
      }
      return url.href;
    }
    async function transfer(url, maximum, destination, expectedHash, options = {}) {
      const { fetchImpl = globalThis.fetch, signal, timeoutMs = destination ? DOWNLOAD_TIMEOUT : 15e3 } = options;
      if (!Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > DOWNLOAD_TIMEOUT) throw new Error("Invalid transfer timeout.");
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);
      const abort = () => controller.abort();
      if (signal?.aborted) controller.abort();
      signal?.addEventListener("abort", abort, { once: true });
      const active = controller.signal;
      let output, response, reader, created = false;
      const chunks = [];
      try {
        active.throwIfAborted();
        if (destination) {
          await plainPath2(destination);
          output = await fs2.open(destination, "wx", 384);
          created = true;
        }
        const channelRequest = url === CHANNEL_URL;
        for (let redirects = 0; redirects <= 3; redirects++) {
          response = await fetchImpl(url, {
            signal: active,
            redirect: "manual",
            credentials: "omit",
            referrerPolicy: "no-referrer",
            headers: { "Accept-Encoding": "identity", "Cache-Control": "no-cache", "User-Agent": "DesignEditor-Beta/1" }
          });
          if (![301, 302, 303, 307, 308].includes(response.status)) break;
          await response.body?.cancel();
          const next = response.headers.get("location");
          if (channelRequest || !next || redirects === 3) throw new Error("Unexpected release redirect.");
          url = redirectAddress(next, url);
        }
        if (response.status !== 200 || !response.body) throw new Error("Release is unavailable.");
        const encoding = response.headers.get("content-encoding");
        if (encoding && encoding !== "identity") throw new Error("Encoded release responses are not accepted.");
        const length = response.headers.get("content-length");
        if (length !== null && (!/^\d+$/.test(length) || Number(length) > maximum || destination && Number(length) !== maximum)) throw new Error("Unexpected release size.");
        let size = 0;
        const hash = createHash("sha256");
        reader = response.body.getReader();
        const cancelReader = () => {
          void reader.cancel().catch(() => {
          });
        };
        active.addEventListener("abort", cancelReader, { once: true });
        try {
          while (true) {
            active.throwIfAborted();
            const { value, done } = await reader.read();
            active.throwIfAborted();
            if (done) break;
            size += value.byteLength;
            if (size > maximum) throw new Error("Release exceeded its size limit.");
            if (output) {
              hash.update(value);
              for (let offset = 0; offset < value.byteLength; ) {
                const written = await output.write(value, offset, value.byteLength - offset);
                if (!written.bytesWritten) throw new Error("Could not write release archive.");
                offset += written.bytesWritten;
              }
            } else chunks.push(Buffer.from(value));
          }
        } finally {
          active.removeEventListener("abort", cancelReader);
        }
        if (output) {
          if (size !== maximum || hash.digest("hex") !== expectedHash) throw new Error("Release checksum or size mismatch.");
          await output.sync();
          await output.close();
          output = null;
          return destination;
        }
        return new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(chunks));
      } catch {
        if (output) {
          await output.close().catch(() => {
          });
          output = null;
        }
        if (created) await fs2.rm(destination, { force: true });
        throw new Error("Release request failed. Your installed version is unchanged.");
      } finally {
        clearTimeout(timer);
        signal?.removeEventListener("abort", abort);
        if (reader) await reader.cancel().catch(() => {
        });
        else await response?.body?.cancel().catch(() => {
        });
      }
    }
    async function readChannel2(options) {
      return parseChannel(await transfer(CHANNEL_URL, MAX_CHANNEL_BYTES, null, null, options), SOURCE2);
    }
    async function downloadArchive2(channel, arch, destination, options) {
      const artifact = selectArtifact2(channel, { platform: "darwin", arch }, SOURCE2);
      if (!artifact || !artifact.filename.endsWith(".tar.gz")) throw new Error("This release has no native archive for this Mac.");
      if (!path2.isAbsolute(destination) || path2.basename(destination) !== artifact.filename) throw new Error("Use the exact release filename in a staging directory.");
      return transfer(artifact.url, artifact.bytes, destination, artifact.sha256, options);
    }
    module2.exports = { readChannel: readChannel2, downloadArchive: downloadArchive2, CHANNEL_URL, DOWNLOAD_TIMEOUT };
  }
});

// mac-client.cjs
var fs = require("node:fs/promises");
var path = require("node:path");
var os = require("node:os");
var { spawn, execFile } = require("node:child_process");
var { promisify } = require("node:util");
var { releaseVersion, selectArtifact } = require_channel();
var { validateManifest, inspectArchive, installArchive, verifyTree, initializeRoot, plainDirectory, plainPath, readBounded, MAX_MANIFEST, MANIFEST, SOURCE } = require_mac_archive();
var { readChannel, downloadArchive } = require_mac_network();
var { withLock } = require_mac_lock();
var exec = promisify(execFile);
var RELEASE_DIR = "app/design-editor-release";
function compareVersions(left, right) {
  releaseVersion(left, "beta");
  releaseVersion(right, "beta");
  const split = (text) => {
    const at = text.indexOf("-");
    return at < 0 ? [text, ""] : [text.slice(0, at), text.slice(at + 1)];
  };
  const integer = (a2, b2) => a2.length !== b2.length ? Math.sign(a2.length - b2.length) : a2 === b2 ? 0 : a2 < b2 ? -1 : 1;
  const [a, as] = split(left), [b, bs] = split(right), ac = a.split("."), bc = b.split(".");
  for (let i = 0; i < 3; i++) {
    const difference = integer(ac[i], bc[i]);
    if (difference) return difference;
  }
  if (!as || !bs) return as === bs ? 0 : as ? -1 : 1;
  const ap = as.split("."), bp = bs.split(".");
  for (let i = 0; i < Math.min(ap.length, bp.length); i++) {
    if (ap[i] === bp[i]) continue;
    const an = /^\d+$/.test(ap[i]), bn = /^\d+$/.test(bp[i]);
    return an && bn ? integer(ap[i], bp[i]) : an !== bn ? an ? -1 : 1 : ap[i] < bp[i] ? -1 : 1;
  }
  return Math.sign(ap.length - bp.length);
}
function runtimePaths(checked) {
  const contents = path.posix.dirname(path.posix.dirname(checked.manifest.executable));
  const paths = {
    node: `${contents}/Resources/agent-runtime/runtime/node`,
    runtime: `${RELEASE_DIR}/mac-runtime.cjs`,
    dispatcher: `${RELEASE_DIR}/dispatch.sh`,
    notices: `${RELEASE_DIR}/THIRD_PARTY_NOTICES.txt`
  };
  for (const file of Object.values(paths)) {
    const entry = checked.entries.get(file);
    if (entry?.type !== "file" || entry.bytes < 1 || file === paths.node && !(entry.mode & 64)) throw new Error("The native release is missing its terminal runtime.");
  }
  return paths;
}
async function currentInstallation(root, arch = process.arch) {
  let state;
  try {
    state = JSON.parse(await readBounded(path.join(root, "current.json"), 4096));
  } catch (error) {
    if (error.code === "ENOENT") return null;
    throw error;
  }
  const keys = ["schemaVersion", "product", "version", "platform", "arch", "directory", "executable", "asar", "archiveSha256"];
  if (!state || typeof state !== "object" || Array.isArray(state) || Object.keys(state).sort().join() !== keys.sort().join()) throw new Error("Invalid installed release record.");
  releaseVersion(state.version, "beta");
  if (state.schemaVersion !== 1 || state.product !== "design-editor" || state.platform !== "darwin" || !["x64", "arm64"].includes(arch) || state.arch !== arch || state.directory !== `versions/${state.version}-darwin-${arch}` || typeof state.archiveSha256 !== "string" || state.archiveSha256.length !== 64 || !/^[a-f0-9]{64}$/.test(state.archiveSha256)) throw new Error("Invalid installed release selection.");
  const directory = path.join(root, state.directory);
  const checked = validateManifest(JSON.parse(await readBounded(path.join(directory, MANIFEST), MAX_MANIFEST)), state.version, arch);
  if (state.executable !== checked.manifest.executable || state.asar !== checked.manifest.asar || (await readBounded(path.join(directory, ".archive-sha256"), 128)).toString("utf8").trim() !== state.archiveSha256) throw new Error("Installed release records disagree.");
  return { state, directory, checked, paths: runtimePaths(checked) };
}
async function updateInstallation(root, { arch = process.arch, fetchImpl, signal, timeoutMs, report = () => {
} } = {}) {
  root = await initializeRoot(root);
  return withLock(root, ".request.lock", async () => {
    const current = await currentInstallation(root, arch);
    const channel = await readChannel({ fetchImpl, signal, timeoutMs });
    const artifact = selectArtifact(channel, { platform: "darwin", arch }, SOURCE);
    if (!artifact || !artifact.filename.endsWith(".tar.gz")) throw new Error("There is no release for this Mac architecture.");
    if (current) {
      const comparison = compareVersions(channel.version, current.state.version);
      if (comparison < 0) return { version: current.state.version, changed: false, status: "newer-installed" };
      if (comparison === 0) {
        if (current.state.archiveSha256 !== artifact.sha256) throw new Error("The server changed an existing version. Your installation was kept.");
        return { version: current.state.version, changed: false, status: "current" };
      }
    }
    const downloads = await plainDirectory(path.join(root, "downloads"));
    const temporary = await fs.mkdtemp(path.join(downloads, ".download-"));
    try {
      report(`Downloading Design Editor ${channel.version}\u2026`);
      const archive = path.join(temporary, artifact.filename);
      await downloadArchive(channel, arch, archive, { fetchImpl, signal, timeoutMs });
      runtimePaths(await inspectArchive(archive, channel, arch));
      const state = await installArchive(archive, channel, root, arch);
      return { version: state.version, changed: true, status: "installed" };
    } finally {
      await fs.rm(temporary, { recursive: true, force: true, maxRetries: 3 });
    }
  });
}
async function registerCommand(root, arch = process.arch) {
  root = await initializeRoot(root);
  const current = await currentInstallation(root, arch);
  if (!current) throw new Error("Install the editor before registering its command.");
  await verifyTree(current.directory, current.checked);
  const text = await readBounded(path.join(current.directory, current.paths.dispatcher), 65536);
  const bin = await plainDirectory(path.join(root, "bin")), file = path.join(bin, "design-editor");
  await plainPath(file);
  try {
    await fs.writeFile(file, text, { flag: "wx", mode: 493 });
  } catch (error) {
    if (error.code !== "EEXIST") throw error;
    if (!(await readBounded(file, 65536)).equals(text)) throw new Error("A different command already exists; it was left unchanged.");
  }
  await fs.chmod(file, 493);
  return file;
}
async function prepareRestart(root, runningVersion, { arch = process.arch } = {}) {
  releaseVersion(runningVersion, "beta");
  root = await initializeRoot(root);
  return withLock(root, ".request.lock", async () => {
    const current = await currentInstallation(root, arch);
    if (!current || compareVersions(current.state.version, runningVersion) <= 0) throw new Error("No newer installed release is ready.");
    await verifyTree(current.directory, current.checked);
    const after = await currentInstallation(root, arch);
    if (JSON.stringify(after?.state) !== JSON.stringify(current.state)) throw new Error("The prepared release changed while checking.");
    return { schemaVersion: 1, version: current.state.version, executable: path.join(current.directory, current.state.executable) };
  });
}
async function registerProfile(root, home, shell) {
  const filename = path.basename(shell || "") === "zsh" ? ".zprofile" : path.basename(shell || "") === "bash" ? ".bash_profile" : null;
  if (!filename) return null;
  if (!path.isAbsolute(home) || !path.isAbsolute(root) || /[\r\n\0]/.test(home + root)) throw new Error("Invalid user-local command location.");
  const file = await plainPath(path.join(home, filename));
  let before = "";
  try {
    before = (await readBounded(file, 1024 * 1024)).toString("utf8");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  const quote = (value) => "'" + value.replaceAll("'", "'\\''") + "'";
  const block = `# >>> Design Editor beta >>>
export PATH=${quote(path.join(root, "bin"))}:"$PATH"
# <<< Design Editor beta <<<
`;
  if (before.includes(block)) return file;
  if (before.includes("# >>> Design Editor beta >>>") || before.includes("# <<< Design Editor beta <<<")) throw new Error("An edited Design Editor PATH entry was left unchanged.");
  const handle = await fs.open(file, "a", 384);
  try {
    await handle.writeFile((before && !before.endsWith("\n") ? "\n" : "") + "\n" + block);
    await handle.sync();
  } finally {
    await handle.close();
  }
  return file;
}
async function findActive(root) {
  const { stdout } = await exec("/bin/ps", ["-axww", "-o", "pid=,comm="], { timeout: 5e3, maxBuffer: 1024 * 1024 });
  const prefix = path.join(root, "versions") + path.sep;
  return stdout.split("\n").some((line) => {
    const match = /^\s*(\d+)\s+(.+)$/.exec(line);
    return match && Number(match[1]) !== process.pid && match[2].startsWith(prefix);
  });
}
async function startDesktop(root, current, project) {
  const executable = await plainPath(path.join(current.directory, current.state.executable));
  const profile = await plainDirectory(path.join(root, "user-data"));
  const env = { ...process.env, DESIGN_EDITOR_CLI_LAUNCH: "1", DESIGN_EDITOR_CLI_USER_DATA: profile, DESIGN_EDITOR_UPDATE_CHECKED_AT: String(Date.now()) };
  for (const key of ["NODE_OPTIONS", "NODE_PATH", "ELECTRON_RUN_AS_NODE", "ELECTRON_OVERRIDE_DIST_PATH"]) delete env[key];
  await new Promise((resolve, reject) => {
    const child = spawn(executable, [`--design-editor-project=${project}`], { cwd: path.dirname(executable), env, shell: false, detached: true, stdio: "ignore" });
    child.once("error", reject);
    child.once("spawn", () => {
      child.unref();
      resolve();
    });
  });
}
async function command(root, args = [], options = {}) {
  if (!Array.isArray(args) || args.length > 1 || args.some((value) => typeof value !== "string")) throw new Error("Use design-editor [folder], update, --version or --help.");
  const action = args[0] || ".", output = options.report || (() => {
  }), arch = options.arch || process.arch;
  if (["--help", "-h"].includes(action)) {
    output("Usage: design-editor [folder] | update | --version");
    return { status: "help" };
  }
  root = await initializeRoot(root);
  if (action === "--version") {
    const current = await currentInstallation(root, arch);
    if (!current) throw new Error("Design Editor is not installed.");
    output(current.state.version);
    return { status: "version", version: current.state.version };
  }
  if (action === "update") {
    const result = await updateInstallation(root, options);
    output(`Design Editor ${result.version} is ready. Existing windows were not restarted.`);
    return result;
  }
  if (action.startsWith("-")) throw new Error("Unknown Design Editor option.");
  const project = await fs.realpath(path.resolve(action));
  if (!(await fs.stat(project)).isDirectory()) throw new Error("Choose an existing project folder.");
  return withLock(root, ".launch.lock", async () => {
    if (await (options.findActive || findActive)(root)) {
      output("Design Editor is already open. Your current work was not changed.");
      return { status: "already-open" };
    }
    try {
      await updateInstallation(root, options);
    } catch {
      if (!await currentInstallation(root, arch)) throw new Error("Design Editor is not installed, and the download failed.");
      output("Could not update. Opening the checked installed version.");
    }
    const current = await currentInstallation(root, arch);
    if (!current) throw new Error("Design Editor is not installed.");
    await verifyTree(current.directory, current.checked);
    await (options.startDesktop || startDesktop)(root, current, project);
    output(`Opened Design Editor ${current.state.version}.`);
    return { status: "opened", version: current.state.version, project };
  });
}
async function main(args = process.argv.slice(2)) {
  if (process.platform !== "darwin" || !["x64", "arm64"].includes(process.arch)) throw new Error("This installer is for supported macOS computers only.");
  const [action, root, ...rest] = args;
  if (action === "install" && args.length === 1) {
    const home = await fs.realpath(os.homedir()), destination = path.join(home, "Library/Application Support/DesignEditorBeta");
    const result = await updateInstallation(destination, { report: console.log });
    const file = await registerCommand(destination);
    const profile = await registerProfile(destination, home, process.env.SHELL);
    console.log(`Design Editor ${result.version} is installed. Run: design-editor .`);
    console.log(profile ? "Open a new terminal to use the command." : `Command path: ${file}`);
    return;
  }
  if (!root || !path.isAbsolute(root)) throw new Error("Use the installed Design Editor dispatcher.");
  if (action === "command") return command(root, rest, { report: console.log });
  if (action === "update-json" && rest.length === 0) {
    const result = await updateInstallation(root);
    console.log(JSON.stringify({ schemaVersion: 1, version: result.version, status: result.status }));
    return;
  }
  if (action === "prepare-restart-json" && rest.length === 1) {
    console.log(JSON.stringify(await prepareRestart(root, rest[0])));
    return;
  }
  throw new Error("Unknown installed-runtime action.");
}
if (require.main === module) main().catch(() => {
  console.error("Design Editor could not complete this operation. Existing files were kept; check the connection or repair the installation.");
  process.exitCode = 1;
});
module.exports = { compareVersions, runtimePaths, currentInstallation, updateInstallation, prepareRestart, registerCommand, registerProfile, command, main };
DESIGN_EDITOR_RUNTIME_2f5499313378e130b8f69c27d3402a5498826a055972863c47011aa297b6bd5e
  "$work/$name/bin/node" "$work/mac-runtime.cjs" install
)

# Dependency notices for the embedded runtime:
# Design Editor macOS installer dependency notices
# 
# @isaacs/fs-minipass@4.0.1
# License: ISC
# 
# The ISC License
# 
# Copyright (c) Isaac Z. Schlueter and Contributors
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# ---
# 
# chownr@3.0.0
# License: BlueOak-1.0.0
# 
# All packages under `src/` are licensed according to the terms in
# their respective `LICENSE` or `LICENSE.md` files.
# 
# The remainder of this project is licensed under the Blue Oak
# Model License, as follows:
# 
# -----
# 
# # Blue Oak Model License
# 
# Version 1.0.0
# 
# ## Purpose
# 
# This license gives everyone as much permission to work with
# this software as possible, while protecting contributors
# from liability.
# 
# ## Acceptance
# 
# In order to receive this license, you must agree to its
# rules.  The rules of this license are both obligations
# under that agreement and conditions to your license.
# You must not do anything with this software that triggers
# a rule that you cannot or will not follow.
# 
# ## Copyright
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe that contributor's
# copyright in it.
# 
# ## Notices
# 
# You must ensure that everyone who gets a copy of
# any part of this software from you, with or without
# changes, also gets the text of this license or a link to
# <https://blueoakcouncil.org/license/1.0.0>.
# 
# ## Excuse
# 
# If anyone notifies you in writing that you have not
# complied with [Notices](#notices), you can keep your
# license by taking all practical steps to comply within 30
# days after the notice.  If you do not do so, your license
# ends immediately.
# 
# ## Patent
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe any patent claims
# they can license or become able to license.
# 
# ## Reliability
# 
# No contributor can revoke this license.
# 
# ## No Liability
# 
# ***As far as the law allows, this software comes as is,
# without any warranty or condition, and no contributor
# will be liable to anyone for any damages related to this
# software or this license, under any kind of legal claim.***
# 
# ---
# 
# graceful-fs@4.2.11
# License: ISC
# 
# The ISC License
# 
# Copyright (c) 2011-2022 Isaac Z. Schlueter, Ben Noordhuis, and Contributors
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# ---
# 
# minipass@7.1.3
# License: BlueOak-1.0.0
# 
# # Blue Oak Model License
# 
# Version 1.0.0
# 
# ## Purpose
# 
# This license gives everyone as much permission to work with
# this software as possible, while protecting contributors
# from liability.
# 
# ## Acceptance
# 
# In order to receive this license, you must agree to its
# rules.  The rules of this license are both obligations
# under that agreement and conditions to your license.
# You must not do anything with this software that triggers
# a rule that you cannot or will not follow.
# 
# ## Copyright
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe that contributor's
# copyright in it.
# 
# ## Notices
# 
# You must ensure that everyone who gets a copy of
# any part of this software from you, with or without
# changes, also gets the text of this license or a link to
# <https://blueoakcouncil.org/license/1.0.0>.
# 
# ## Excuse
# 
# If anyone notifies you in writing that you have not
# complied with [Notices](#notices), you can keep your
# license by taking all practical steps to comply within 30
# days after the notice.  If you do not do so, your license
# ends immediately.
# 
# ## Patent
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe any patent claims
# they can license or become able to license.
# 
# ## Reliability
# 
# No contributor can revoke this license.
# 
# ## No Liability
# 
# ***As far as the law allows, this software comes as is,
# without any warranty or condition, and no contributor
# will be liable to anyone for any damages related to this
# software or this license, under any kind of legal claim.***
# 
# ---
# 
# minizlib@3.1.0
# License: MIT
# 
# Minizlib was created by Isaac Z. Schlueter.
# It is a derivative work of the Node.js project.
# 
# """
# Copyright (c) 2017-2023 Isaac Z. Schlueter and Contributors
# Copyright (c) 2017-2023 Node.js contributors. All rights reserved.
# Copyright (c) 2017-2023 Joyent, Inc. and other Node contributors. All rights reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# """
# 
# ---
# 
# proper-lockfile@4.1.2
# License: MIT
# 
# The MIT License (MIT)
# 
# Copyright (c) 2018 Made With MOXY Lda <hello@moxy.studio>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# ---
# 
# retry@0.12.0
# License: MIT
# 
# Copyright (c) 2011:
# Tim Koschützki (tim@debuggable.com)
# Felix Geisendörfer (felix@debuggable.com)
# 
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
# 
# ---
# 
# signal-exit@3.0.7
# License: ISC
# 
# The ISC License
# 
# Copyright (c) 2015, Contributors
# 
# Permission to use, copy, modify, and/or distribute this software
# for any purpose with or without fee is hereby granted, provided
# that the above copyright notice and this permission notice
# appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE
# LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# ---
# 
# tar@7.5.22
# License: BlueOak-1.0.0
# 
# # Blue Oak Model License
# 
# Version 1.0.0
# 
# ## Purpose
# 
# This license gives everyone as much permission to work with
# this software as possible, while protecting contributors
# from liability.
# 
# ## Acceptance
# 
# In order to receive this license, you must agree to its
# rules.  The rules of this license are both obligations
# under that agreement and conditions to your license.
# You must not do anything with this software that triggers
# a rule that you cannot or will not follow.
# 
# ## Copyright
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe that contributor's
# copyright in it.
# 
# ## Notices
# 
# You must ensure that everyone who gets a copy of
# any part of this software from you, with or without
# changes, also gets the text of this license or a link to
# <https://blueoakcouncil.org/license/1.0.0>.
# 
# ## Excuse
# 
# If anyone notifies you in writing that you have not
# complied with [Notices](#notices), you can keep your
# license by taking all practical steps to comply within 30
# days after the notice.  If you do not do so, your license
# ends immediately.
# 
# ## Patent
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe any patent claims
# they can license or become able to license.
# 
# ## Reliability
# 
# No contributor can revoke this license.
# 
# ## No Liability
# 
# ***As far as the law allows, this software comes as is,
# without any warranty or condition, and no contributor
# will be liable to anyone for any damages related to this
# software or this license, under any kind of legal claim.***
# 
# ---
# 
# yallist@5.0.0
# License: BlueOak-1.0.0
# 
# All packages under `src/` are licensed according to the terms in
# their respective `LICENSE` or `LICENSE.md` files.
# 
# The remainder of this project is licensed under the Blue Oak
# Model License, as follows:
# 
# -----
# 
# # Blue Oak Model License
# 
# Version 1.0.0
# 
# ## Purpose
# 
# This license gives everyone as much permission to work with
# this software as possible, while protecting contributors
# from liability.
# 
# ## Acceptance
# 
# In order to receive this license, you must agree to its
# rules.  The rules of this license are both obligations
# under that agreement and conditions to your license.
# You must not do anything with this software that triggers
# a rule that you cannot or will not follow.
# 
# ## Copyright
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe that contributor's
# copyright in it.
# 
# ## Notices
# 
# You must ensure that everyone who gets a copy of
# any part of this software from you, with or without
# changes, also gets the text of this license or a link to
# <https://blueoakcouncil.org/license/1.0.0>.
# 
# ## Excuse
# 
# If anyone notifies you in writing that you have not
# complied with [Notices](#notices), you can keep your
# license by taking all practical steps to comply within 30
# days after the notice.  If you do not do so, your license
# ends immediately.
# 
# ## Patent
# 
# Each contributor licenses you to do everything with this
# software that would otherwise infringe any patent claims
# they can license or become able to license.
# 
# ## Reliability
# 
# No contributor can revoke this license.
# 
# ## No Liability
# 
# ***As far as the law allows, this software comes as is,
# without any warranty or condition, and no contributor
# will be liable to anyone for any damages related to this
# software or this license, under any kind of legal claim.***
# 
