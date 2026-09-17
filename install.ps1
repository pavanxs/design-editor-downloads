# Design Editor Windows beta installer. HTTPS/checksum integrity; no signature claim.
# No npm prerequisite or security-policy bypass. Not live until release publication.
& {
# Generated from the reviewed installer/client sources. Do not edit generated copies.
# Windows PowerShell 5.1 / .NET installation core. No npm, administrator changes,
# security-policy changes, process termination, or network access happens here.
# The caller must supply the archive's expected release metadata from its fixed
# HTTPS feed. These hashes are integrity checks, not publisher signatures.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression

function Assert-DEPlainPath([string] $Path) {
    $full = [IO.Path]::GetFullPath($Path)
    $cursor = $full
    while ($cursor) {
        if ([IO.File]::Exists($cursor) -or [IO.Directory]::Exists($cursor)) {
            if (([IO.File]::GetAttributes($cursor) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Installation paths must not pass through a link or junction.'
            }
        }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $full
}

function Assert-DEName([string] $Name) {
    if (!$Name -or $Name.Length -gt 400 -or $Name.StartsWith('/') -or $Name -match '[\\\x00-\x1f\x7f:<>"|?*]') { throw 'Unsafe archive path.' }
    foreach ($part in $Name.Split('/')) {
        if (!$part -or $part -eq '.' -or $part -eq '..' -or $part -match '[. ]$' -or
            $part -match '^(con|prn|aux|nul|com[1-9]|lpt[1-9])($|\.)' -or
            $part -match '^(\.git|\.github|\.env(\..*)?|\.npmrc|\.pypirc|\.DS_Store)$') { throw 'Unsafe archive path.' }
    }
}

function Assert-DEKeys($Value, [string[]] $Keys) {
    if ($null -eq $Value -or $Value -isnot [pscustomobject]) { throw 'Invalid release object.' }
    $actual = @($Value.PSObject.Properties.Name)
    if ($actual.Count -ne $Keys.Count) { throw 'Unexpected release fields.' }
    foreach ($key in $Keys) { if ($actual -cnotcontains $key) { throw 'Missing release field.' } }
}

function Test-DEInteger($Value, [long] $Minimum, [long] $Maximum) {
    # JSON booleans are ValueTypes too; never accept true as size/schema 1.
    return (($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) -and
        $Value -ge $Minimum -and $Value -le $Maximum -and $Value -eq [math]::Floor($Value))
}

function Get-DEHash([IO.Stream] $Stream) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($algorithm.ComputeHash($Stream)).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}

function Get-DEFileHash([string] $File) {
    $stream = [IO.File]::Open($File, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try { return Get-DEHash $stream } finally { $stream.Dispose() }
}

function Assert-DEZipDirectory([IO.Stream] $Stream) {
    # Bound central-directory allocation before ZipArchive materializes Entries.
    # Our <2 GiB / <30k-entry Windows bundles do not require ZIP64 or multi-disk ZIP.
    if ($Stream.Length -lt 22) { throw 'Incomplete ZIP archive.' }
    $length = [int][math]::Min(65557, $Stream.Length)
    $tail = [byte[]]::new($length); $Stream.Position = $Stream.Length - $length
    $read = 0
    while ($read -lt $length) { $n = $Stream.Read($tail, $read, $length - $read); if (!$n) { throw 'Incomplete ZIP directory.' }; $read += $n }
    $found = $false
    for ($i = $length - 22; $i -ge 0; $i--) {
        if ([BitConverter]::ToUInt32($tail, $i) -ne 0x06054b50 -or $i + 22 + [BitConverter]::ToUInt16($tail, $i + 20) -ne $length) { continue }
        $count = [BitConverter]::ToUInt16($tail, $i + 10)
        $size = [BitConverter]::ToUInt32($tail, $i + 12); $offset = [BitConverter]::ToUInt32($tail, $i + 16)
        if ([BitConverter]::ToUInt16($tail, $i + 4) -ne 0 -or [BitConverter]::ToUInt16($tail, $i + 6) -ne 0 -or
            [BitConverter]::ToUInt16($tail, $i + 8) -ne $count -or $count -lt 2 -or $count -gt 30001 -or
            $size -gt 16777216 -or ([long]$offset + $size) -ne ($Stream.Length - $length + $i)) { throw 'Unsupported or oversized ZIP directory.' }
        $found = $true; break
    }
    if (!$found) { throw 'ZIP directory was not found.' }
    $Stream.Position = 0
}

function Read-DEManifest($Entry) {
    if ($Entry.Length -lt 1 -or $Entry.Length -gt 8388608) { throw 'Bundle manifest is outside its size limit.' }
    $stream = $Entry.Open(); $memory = [IO.MemoryStream]::new(); $buffer = [byte[]]::new(65536)
    try {
        while (($count = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($memory.Length + $count -gt $Entry.Length) { throw 'Bundle manifest exceeded its declared size.' }
            $memory.Write($buffer, 0, $count)
        }
        if ($memory.Length -ne $Entry.Length) { throw 'Incomplete bundle manifest.' }
        $encoding = [Text.UTF8Encoding]::new($false, $true)
        try { return ConvertFrom-Json -InputObject $encoding.GetString($memory.ToArray()) }
        catch { throw 'Bundle manifest is not valid UTF-8 JSON.' }
    } finally { $stream.Dispose(); $memory.Dispose() }
}

function Assert-DEManifest($Manifest, [string] $Version, [string] $Architecture, $Entries) {
    Assert-DEKeys $Manifest @('schemaVersion', 'product', 'version', 'platform', 'arch', 'electron', 'executable', 'asar', 'files')
    if (!(Test-DEInteger $Manifest.schemaVersion 1 1) -or $Manifest.product -cne 'design-editor' -or $Manifest.platform -cne 'win32' -or
        $Manifest.version -cne $Version -or $Manifest.arch -cne $Architecture -or $Manifest.electron -cnotmatch '^\d+\.\d+\.\d+$') { throw 'Bundle does not match the requested release and target.' }
    if ($Manifest.files -isnot [array] -or $Manifest.files.Count -lt 1 -or $Manifest.files.Count -gt 30000) { throw 'Invalid bundle file inventory.' }
    if ($Manifest.executable -cnotmatch '^app/[A-Za-z][A-Za-z0-9 _-]{0,60}\.exe$' -or $Manifest.asar -cne 'app/resources/app.asar') { throw 'Invalid native entry points.' }
    $files = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    [long] $total = 0
    foreach ($file in $Manifest.files) {
        Assert-DEKeys $file @('path', 'type', 'bytes', 'sha256', 'mode')
        Assert-DEName $file.path
        if (!$file.path.StartsWith('app/', [StringComparison]::Ordinal) -or $file.type -cne 'file' -or
            $file.sha256 -isnot [string] -or $file.sha256.Length -ne 64 -or $file.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
            !(Test-DEInteger $file.bytes 0 2147483647) -or !(Test-DEInteger $file.mode 0 511)) { throw 'Invalid bundle file entry.' }
        if ($files.ContainsKey($file.path) -or !$Entries.ContainsKey($file.path)) { throw 'Duplicate or missing bundle file.' }
        $entry = $Entries[$file.path]
        if ($entry.FullName -cne $file.path -or $entry.Length -ne $file.bytes) { throw 'Archive inventory differs from its manifest.' }
        $total += $file.bytes
        if ($total -gt 4294967296) { throw 'Bundle exceeds the expanded-size limit.' }
        $files.Add($file.path, $file)
    }
    if (!$files.ContainsKey($Manifest.executable) -or !$files.ContainsKey($Manifest.asar) -or $Entries.Count -ne $files.Count + 1) { throw 'Bundle contains missing or undeclared files.' }
    foreach ($name in $files.Keys) {
        $parent = $name
        while ($parent.Contains('/')) {
            $parent = $parent.Substring(0, $parent.LastIndexOf('/'))
            if ($files.ContainsKey($parent)) { throw 'An archive file conflicts with a directory.' }
        }
    }
    return $files
}

function Copy-DEEntry($Entry, $Expected, [string] $Destination) {
    $inputStream = $Entry.Open(); $output = $null; $hash = [Security.Cryptography.SHA256]::Create()
    try {
        $output = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $buffer = [byte[]]::new(65536); [long] $written = 0
        while (($count = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $written += $count
            if ($written -gt $Expected.bytes) { throw 'Expanded file exceeded its declared size.' }
            [void] $hash.TransformBlock($buffer, 0, $count, $null, 0)
            $output.Write($buffer, 0, $count)
        }
        [void] $hash.TransformFinalBlock([byte[]]::new(0), 0, 0)
        $actual = [BitConverter]::ToString($hash.Hash).Replace('-', '').ToLowerInvariant()
        if ($written -ne $Expected.bytes -or $actual -cne $Expected.sha256) { throw 'Extracted file failed size or SHA-256 verification.' }
        $output.Flush($true)
    } finally { $inputStream.Dispose(); if ($output) { $output.Dispose() }; $hash.Dispose() }
}

function Assert-DEExecutable([string] $File, [string] $Architecture) {
    $stream = [IO.File]::OpenRead($File); $reader = [IO.BinaryReader]::new($stream)
    try {
        if ($stream.Length -lt 64 -or $reader.ReadUInt16() -ne 0x5a4d) { throw 'Missing Windows executable header.' }
        $stream.Position = 60; $offset = $reader.ReadUInt32()
        if ($offset -lt 64 -or $offset + 6 -gt $stream.Length) { throw 'Invalid Windows executable header.' }
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x4550) { throw 'Invalid Windows executable header.' }
        $machine = $reader.ReadUInt16(); $expected = if ($Architecture -eq 'x64') { 0x8664 } else { 0xaa64 }
        if ($machine -ne $expected) { throw 'Windows executable architecture mismatch.' }
    } finally { $reader.Dispose(); $stream.Dispose() }
}

function Initialize-DEInstallRoot([string] $InstallRoot) {
    if ($InstallRoot -notmatch '^[A-Za-z]:[\\/]') { throw 'Use an absolute local-drive installation path.' }
    $root = Assert-DEPlainPath $InstallRoot
    $owner = Join-Path $root '.design-editor-root'
    if ([IO.Directory]::Exists($root)) {
        if (![IO.File]::Exists($owner) -and [IO.Directory]::GetFileSystemEntries($root).Length -gt 0) { throw 'The destination is not an editor-owned installation.' }
    } else { [void] [IO.Directory]::CreateDirectory($root) }
    Assert-DEPlainPath $owner | Out-Null
    if (![IO.File]::Exists($owner)) {
        $marker = [IO.File]::Open($owner, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $text = [Text.Encoding]::UTF8.GetBytes('Design Editor installation v1'); $marker.Write($text, 0, $text.Length) } finally { $marker.Dispose() }
    }
    if (([IO.FileInfo]$owner).Length -gt 128 -or [IO.File]::ReadAllText($owner) -cne 'Design Editor installation v1') { throw 'Installation ownership marker is invalid.' }
    return $root
}

function Install-DesignEditorArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string] $ArchivePath,
        [Parameter(Mandatory=$true)][string] $InstallRoot,
        [Parameter(Mandatory=$true)][string] $Version,
        [Parameter(Mandatory=$true)][ValidateSet('x64','arm64')][string] $Architecture,
        [Parameter(Mandatory=$true)][string] $Sha256,
        [Parameter(Mandatory=$true)][long] $Bytes
    )
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'This installation core is for Windows.' }
    $nativeArch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    if ($nativeArch -cne $Architecture) { throw 'This release is not for the current Windows architecture.' }
    if ($Version.Length -gt 96 -or $Version.Trim() -cne $Version -or $Version -cnotmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$') { throw 'Use an exact release version.' }
    if ($Version.Contains('-')) {
        foreach ($part in $Version.Substring($Version.IndexOf('-') + 1).Split('.')) { if ($part -match '^0\d+$') { throw 'Invalid numeric prerelease identifier.' } }
    }
    if ($Sha256.Length -ne 64 -or $Sha256 -cnotmatch '^[a-f0-9]{64}$' -or $Bytes -lt 1 -or $Bytes -gt 2147483647) { throw 'Invalid archive verification information.' }
    if ($InstallRoot -notmatch '^[A-Za-z]:[\\/]' -or $ArchivePath -notmatch '^[A-Za-z]:[\\/]') { throw 'Use absolute local-drive installation and archive paths.' }
    $root = Initialize-DEInstallRoot $InstallRoot; $archiveFile = Assert-DEPlainPath $ArchivePath
    $lockPath = Join-Path $root '.install.lock'; Assert-DEPlainPath $lockPath | Out-Null
    try { $lock = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { throw 'Another installation or update is running. Retry when it finishes.' }
    $stream = $null; $zip = $null; $stage = $null; $next = $null
    try {
        $stream = [IO.File]::Open($archiveFile, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        if ($stream.Length -ne $Bytes -or (Get-DEHash $stream) -cne $Sha256) { throw 'Archive failed size or SHA-256 verification.' }
        Assert-DEZipDirectory $stream
        $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Read, $true)
        if ($zip.Entries.Count -lt 2 -or $zip.Entries.Count -gt 30001) { throw 'Archive entry-count limit exceeded.' }
        $entries = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        $all = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $zip.Entries) {
            $isDirectory = $entry.FullName.EndsWith('/'); $name = $entry.FullName.TrimEnd('/')
            Assert-DEName $name
            if ($name -cne 'design-editor-build.json' -and $name -cne 'app' -and !$name.StartsWith('app/', [StringComparison]::Ordinal)) { throw 'Archive contains an unexpected top-level path.' }
            $kind = ($entry.ExternalAttributes -shr 16) -band 0xf000
            if ($kind -notin @(0, 0x8000, 0x4000) -or (($entry.ExternalAttributes -band 0xffff) -band 0x400) -ne 0) { throw 'Archive links and special entries are not supported on Windows.' }
            if (!$all.Add($name)) { throw 'Archive contains duplicate paths.' }
            if ($isDirectory) { if ($entry.Length -ne 0) { throw 'Invalid archive directory.' }; continue }
            if ($entry.Length -gt 2147483647) { throw 'Archive file is too large.' }
            $entries.Add($name, $entry)
        }
        if (!$entries.ContainsKey('design-editor-build.json')) { throw 'Native bundle manifest is missing.' }
        $manifest = Read-DEManifest $entries['design-editor-build.json']
        $files = Assert-DEManifest $manifest $Version $Architecture $entries
        $versions = Join-Path $root 'versions'; Assert-DEPlainPath $versions | Out-Null; [void] [IO.Directory]::CreateDirectory($versions)
        $destination = Join-Path $versions ($Version + '-win32-' + $Architecture); Assert-DEPlainPath $destination | Out-Null
        $alreadyPresent = [IO.Directory]::Exists($destination)
        if ($alreadyPresent) {
            foreach ($file in $manifest.files) {
                $installed = Assert-DEPlainPath (Join-Path $destination $file.path)
                if (![IO.File]::Exists($installed) -or ([IO.FileInfo]$installed).Length -ne $file.bytes -or (Get-DEFileHash $installed) -cne $file.sha256) { throw 'An existing version differs or is damaged; it was not overwritten.' }
            }
        } else {
            $stage = Join-Path $versions ('.staging-' + [Guid]::NewGuid().ToString('N')); [void] [IO.Directory]::CreateDirectory($stage)
            $prefix = [IO.Path]::GetFullPath($stage) + [IO.Path]::DirectorySeparatorChar
            foreach ($file in $manifest.files) {
                $target = [IO.Path]::GetFullPath((Join-Path $stage $file.path))
                if (!$target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive extraction left the staging directory.' }
                [void] [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
                Copy-DEEntry $entries[$file.path] $file $target
            }
            Assert-DEExecutable (Join-Path $stage $manifest.executable) $Architecture
            [IO.File]::WriteAllText((Join-Path $stage 'design-editor-build.json'), ($manifest | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
            [IO.Directory]::Move($stage, $destination); $stage = $null
        }
        $state = [ordered]@{ schemaVersion = 1; product = 'design-editor'; version = $Version; platform = 'win32'; arch = $Architecture; directory = ('versions/' + $Version + '-win32-' + $Architecture); executable = $manifest.executable; archiveSha256 = $Sha256 }
        $current = Join-Path $root 'current.json'; Assert-DEPlainPath $current | Out-Null
        $next = Join-Path $root ('.current-' + [Guid]::NewGuid().ToString('N') + '.json')
        $stateBytes = [Text.UTF8Encoding]::new($false).GetBytes(($state | ConvertTo-Json))
        $writer = [IO.File]::Open($next, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $writer.Write($stateBytes, 0, $stateBytes.Length); $writer.Flush($true) } finally { $writer.Dispose() }
        if ([IO.File]::Exists($current)) {
            if ([IO.File]::ReadAllText($current) -ceq ($state | ConvertTo-Json)) { [IO.File]::Delete($next) }
            else {
                # Windows PowerShell converts a null string argument to an empty
                # path. Use a real, owned backup path for File.Replace instead.
                $previous = Join-Path $root 'previous.json'; Assert-DEPlainPath $previous | Out-Null
                [IO.File]::Replace($next, $current, $previous)
            }
        } else { [IO.File]::Move($next, $current) }
        $next = $null
        return [pscustomobject]@{ InstallRoot = $root; Version = $Version; Executable = (Join-Path $destination $manifest.executable); AlreadyPresent = $alreadyPresent; CurrentFile = $current }
    } finally {
        try {
            if ($zip) { $zip.Dispose() }; if ($stream) { $stream.Dispose() }
            if ($stage -and [IO.Directory]::Exists($stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
            if ($next -and [IO.File]::Exists($next)) { [IO.File]::Delete($next) }
        } finally { $lock.Dispose() }
    }
}


$script:DELauncherShim = @'
# Stable local dispatcher. Never downloads or executes a remote script.
# Versioned update code is installed and replaced with the verified app archive.
$ErrorActionPreference = 'Stop'
try {
    $root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $stateFile = Join-Path $root 'current.json'
    if (![IO.File]::Exists($stateFile) -or ([IO.FileInfo]$stateFile).Length -gt 4096) { throw 'Run the Design Editor installer first.' }
    $state = [IO.File]::ReadAllText($stateFile) | ConvertFrom-Json
    if ($state.schemaVersion -ne 1 -or $state.product -cne 'design-editor' -or $state.platform -cne 'win32' -or
        $state.version -isnot [string] -or $state.version.Length -gt 96 -or $state.version.Trim() -cne $state.version -or
        $state.version -cnotmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$' -or
        $state.arch -cnotin @('x64','arm64') -or $state.directory -cne ('versions/' + $state.version + '-win32-' + $state.arch)) { throw 'Invalid local release selection.' }
    $launch = Join-Path (Join-Path $root $state.directory) 'app/resources/design-editor-release/launch.ps1'
    $cursor = [IO.Path]::GetFullPath($launch)
    while ($cursor) {
        if (([IO.File]::Exists($cursor) -or [IO.Directory]::Exists($cursor)) -and
            (([IO.File]::GetAttributes($cursor) -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw 'Local release paths must not be links.' }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    if (![IO.File]::Exists($launch)) { throw 'The installed command files are missing. Rerun the installer.' }
    & $launch -InstallRoot $root -CommandArguments @args
} catch { Write-Error $_.Exception.Message; exit 1 }
'@
$script:DECommandShim = @'
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File "%~dp0design-editor.ps1" %*
'@

# Combined with windows-install.psm1 by render-windows.cjs. No top-level network
# or install action. The public bootstrap and installed version use these same
# functions; future updates can replace the verification code with the app.
Add-Type -AssemblyName System.Net.Http
$script:DERepository = 'pavanxs/design-editor-downloads'
$script:DEChannel = 'beta'
$script:DEChannelUrl = 'https://raw.githubusercontent.com/pavanxs/design-editor-downloads/main/channels/beta.json'

function Assert-DEVersion([string] $Version) {
    if (!$Version -or $Version.Length -gt 96 -or $Version.Trim() -cne $Version -or
        $Version -cnotmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$') { throw 'Invalid release version.' }
    if ($Version.Contains('-')) {
        foreach ($part in $Version.Substring($Version.IndexOf('-') + 1).Split('.')) { if ($part -match '^0\d+$') { throw 'Invalid numeric prerelease identifier.' } }
    }
}

function Compare-DEVersion([string] $Left, [string] $Right) {
    Assert-DEVersion $Left; Assert-DEVersion $Right
    $a = @($Left -split '-', 2); $b = @($Right -split '-', 2)
    $ac = $a[0].Split('.'); $bc = $b[0].Split('.')
    for ($i = 0; $i -lt 3; $i++) {
        if ($ac[$i].Length -ne $bc[$i].Length) { return [math]::Sign($ac[$i].Length - $bc[$i].Length) }
        $compare = [string]::CompareOrdinal($ac[$i], $bc[$i]); if ($compare -ne 0) { return [math]::Sign($compare) }
    }
    if ($a.Length -eq 1 -and $b.Length -eq 1) { return 0 }
    if ($a.Length -eq 1) { return 1 }; if ($b.Length -eq 1) { return -1 }
    $ap = $a[1].Split('.'); $bp = $b[1].Split('.')
    for ($i = 0; $i -lt [math]::Min($ap.Length, $bp.Length); $i++) {
        $an = $ap[$i] -match '^\d+$'; $bn = $bp[$i] -match '^\d+$'
        if ($an -and !$bn) { return -1 }; if (!$an -and $bn) { return 1 }
        if ($an -and $ap[$i].Length -ne $bp[$i].Length) { return [math]::Sign($ap[$i].Length - $bp[$i].Length) }
        $compare = [string]::CompareOrdinal($ap[$i], $bp[$i]); if ($compare -ne 0) { return [math]::Sign($compare) }
    }
    return [math]::Sign($ap.Length - $bp.Length)
}

function ConvertFrom-DEChannel([string] $Text, [string] $Architecture) {
    if ([Text.Encoding]::UTF8.GetByteCount($Text) -gt 65536) { throw 'Release information is too large.' }
    try { $channel = ConvertFrom-Json -InputObject $Text } catch { throw 'Release information is not valid JSON.' }
    Assert-DEKeys $channel @('schemaVersion','product','repository','channel','version','publishedAt','artifacts')
    if (!(Test-DEInteger $channel.schemaVersion 1 1) -or $channel.product -cne 'design-editor' -or $channel.repository -cne $script:DERepository -or $channel.channel -cne $script:DEChannel) { throw 'Release information came from an unexpected source or format.' }
    Assert-DEVersion $channel.version
    $date = [DateTimeOffset]::MinValue
    if ($channel.publishedAt -isnot [string] -or $channel.publishedAt.Length -ne 24 -or
        ![DateTimeOffset]::TryParseExact($channel.publishedAt,"yyyy-MM-dd'T'HH:mm:ss.fff'Z'",[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal,[ref]$date)) { throw 'Invalid release timestamp.' }
    if ($channel.artifacts -isnot [array] -or $channel.artifacts.Count -lt 1 -or $channel.artifacts.Count -gt 4) { throw 'Invalid release build list.' }
    $seen = @{}; $selected = $null
    foreach ($artifact in $channel.artifacts) {
        Assert-DEKeys $artifact @('platform','arch','filename','bytes','sha256','url')
        $target = $artifact.platform + '-' + $artifact.arch
        if ($target -cnotin @('win32-x64','win32-arm64','darwin-x64','darwin-arm64') -or $seen.ContainsKey($target)) { throw 'Invalid or duplicate release target.' }
        $seen[$target] = $true
        $stem = 'design-editor-' + $channel.version + '-' + $target
        if ($artifact.filename -cne ($stem + '.zip') -and !($artifact.platform -ceq 'darwin' -and $artifact.filename -ceq ($stem + '.tar.gz'))) { throw 'Release filename does not match its target.' }
        if (!(Test-DEInteger $artifact.bytes 1 2147483647) -or
            $artifact.sha256 -isnot [string] -or $artifact.sha256.Length -ne 64 -or $artifact.sha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'Invalid release size or checksum.' }
        $url = 'https://github.com/' + $script:DERepository + '/releases/download/v' + $channel.version + '/' + $artifact.filename
        if ($artifact.url -cne $url) { throw 'Release download address is not the expected versioned GitHub asset.' }
        if ($target -ceq ('win32-' + $Architecture)) { $selected = $artifact }
    }
    if (!$selected) { throw 'This release has no build for your Windows architecture.' }
    return [pscustomobject]@{ Version = $channel.version; Artifact = $selected }
}

function Assert-DEHttpAddress([string] $Url, [bool] $Redirect) {
    $uri = $null
    if (![Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -cne 'https' -or !$uri.IsDefaultPort -or $uri.UserInfo -or $uri.Fragment) { throw 'Unapproved release download address.' }
    if ($Redirect) {
        if ($uri.Host -cnotin @('release-assets.githubusercontent.com','objects.githubusercontent.com')) { throw 'Release redirect left the approved hosts.' }
    } elseif ($Url -cne $script:DEChannelUrl -and !$Url.StartsWith(('https://github.com/' + $script:DERepository + '/releases/download/v'), [StringComparison]::Ordinal)) { throw 'Unapproved release download address.' }
    return $uri
}

function New-DEHttpHandler {
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false; $handler.UseCookies = $false; $handler.UseDefaultCredentials = $false
    $handler.AutomaticDecompression = [Net.DecompressionMethods]::None
    return $handler
}

function Receive-DEHttps([string] $Url, [long] $Limit, [string] $Destination = '', [int] $TimeoutSeconds = 15) {
    if ($Limit -lt 1 -or $Limit -gt 2147483647 -or $TimeoutSeconds -lt 1 -or $TimeoutSeconds -gt 300) { throw 'Invalid release transfer limits.' }
    $uri = Assert-DEHttpAddress $Url $false
    $handler = New-DEHttpHandler; $client = [Net.Http.HttpClient]::new($handler); $cancel = [Threading.CancellationTokenSource]::new()
    $client.Timeout = [Threading.Timeout]::InfiniteTimeSpan; $cancel.CancelAfter($TimeoutSeconds * 1000)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('DesignEditor-Beta/1'); $client.DefaultRequestHeaders.AcceptEncoding.ParseAdd('identity')
    $client.DefaultRequestHeaders.CacheControl = [Net.Http.Headers.CacheControlHeaderValue]::new(); $client.DefaultRequestHeaders.CacheControl.NoCache = $true
    $response = $null; $output = $null; $created = $false; $completed = $false
    try {
        for ($redirects = 0; $redirects -le 3; $redirects++) {
            $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get, $uri)
            try { $response = $client.SendAsync($request,[Net.Http.HttpCompletionOption]::ResponseHeadersRead,$cancel.Token).GetAwaiter().GetResult() } finally { $request.Dispose() }
            if ([int]$response.StatusCode -in @(301,302,303,307,308)) {
                if ($Url -ceq $script:DEChannelUrl -or $redirects -eq 3 -or !$response.Headers.Location) { throw 'Unexpected release redirect.' }
                $next = [Uri]::new($uri, $response.Headers.Location); $uri = Assert-DEHttpAddress $next.AbsoluteUri $true
                $response.Dispose(); $response = $null; continue
            }
            break
        }
        if ([int]$response.StatusCode -ne 200) { throw 'Release download is unavailable.' }
        if ($response.Content.Headers.ContentEncoding.Count -gt 0) { throw 'Encoded release responses are not supported.' }
        $length = $response.Content.Headers.ContentLength
        if ($null -ne $length -and ($length -gt $Limit -or ($Destination -and $length -ne $Limit))) { throw 'Release size does not match its information.' }
        if ($Destination) { $output = [IO.File]::Open($Destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None); $created = $true }
        else { $output = [IO.MemoryStream]::new() }
        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult(); $buffer = [byte[]]::new(65536); [long]$total = 0
        try {
            while (($count = $stream.ReadAsync($buffer,0,$buffer.Length,$cancel.Token).GetAwaiter().GetResult()) -gt 0) {
                $cancel.Token.ThrowIfCancellationRequested(); $total += $count
                if ($total -gt $Limit) { throw 'Release download exceeded its size limit.' }
                $output.Write($buffer,0,$count)
            }
        } finally { $stream.Dispose() }
        if ($Destination) {
            if ($total -ne $Limit) { throw 'Release download is incomplete.' }
            $output.Flush($true); $completed = $true; return $Destination
        }
        return [Text.UTF8Encoding]::new($false,$true).GetString($output.ToArray())
    } catch {
        # Never echo server bodies, redirect query strings or credential-bearing
        # transport exceptions into public terminals or the product interface.
        if ($cancel.IsCancellationRequested) { throw 'The release check or download timed out. Your existing install is unchanged.' }
        throw 'The release check or download failed validation. Your existing install is unchanged.'
    } finally {
        if ($output) { $output.Dispose() }; if ($response) { $response.Dispose() }; $client.Dispose(); $cancel.Dispose()
        if ($created -and !$completed -and [IO.File]::Exists($Destination)) { [IO.File]::Delete($Destination) }
    }
}

function Read-DECurrent([string] $InstallRoot) {
    $file = Assert-DEPlainPath (Join-Path $InstallRoot 'current.json')
    if (![IO.File]::Exists($file)) { return $null }
    if (([IO.FileInfo]$file).Length -gt 4096) { throw 'The installed-version record is invalid.' }
    try { $state = [IO.File]::ReadAllText($file) | ConvertFrom-Json } catch { throw 'The installed-version record is invalid.' }
    Assert-DEKeys $state @('schemaVersion','product','version','platform','arch','directory','executable','archiveSha256')
    Assert-DEVersion $state.version
    $arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    if (!(Test-DEInteger $state.schemaVersion 1 1) -or $state.product -cne 'design-editor' -or $state.platform -cne 'win32' -or $state.arch -cne $arch -or
        $state.directory -cne ('versions/' + $state.version + '-win32-' + $arch) -or
        $state.executable -cnotmatch '^app/[A-Za-z][A-Za-z0-9 _-]{0,60}\.exe$' -or
        $state.archiveSha256 -isnot [string] -or $state.archiveSha256.Length -ne 64 -or $state.archiveSha256 -cnotmatch '^[0-9a-f]{64}$') { throw 'The installed-version record is invalid.' }
    $executable = Assert-DEPlainPath (Join-Path (Join-Path $InstallRoot $state.directory) $state.executable)
    if (![IO.File]::Exists($executable)) { throw 'Installed application files are missing. Rerun the installer to repair them.' }
    return $state
}

function Update-DesignEditorInstallation([string] $InstallRoot) {
    $root = Initialize-DEInstallRoot $InstallRoot
    $lockFile = Assert-DEPlainPath (Join-Path $root '.update.lock')
    try { $lock = [IO.File]::Open($lockFile,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
    catch { throw 'Another update is running. Try again when it finishes.' }
    $temporary = $null
    try {
        $arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
        if ($arch -cnotin @('x64','arm64')) { throw 'This Windows architecture is not supported.' }
        $current = Read-DECurrent $root
        $release = ConvertFrom-DEChannel (Receive-DEHttps $script:DEChannelUrl 65536) $arch
        if ($current) {
            $comparison = Compare-DEVersion $release.Version $current.version
            if ($comparison -lt 0) { return [pscustomobject]@{ Version = $current.version; Changed = $false; Status = 'newer-installed' } }
            if ($comparison -eq 0) {
                if ($current.archiveSha256 -cne $release.Artifact.sha256) { throw 'This version has changed on the server; the existing installation was kept.' }
                return [pscustomobject]@{ Version = $current.version; Changed = $false; Status = 'current' }
            }
        }
        $downloads = Assert-DEPlainPath (Join-Path $root 'downloads'); [void][IO.Directory]::CreateDirectory($downloads)
        $temporary = Join-Path $downloads ([Guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($temporary)
        $archive = Join-Path $temporary $release.Artifact.filename
        Write-Host ('Downloading Design Editor ' + $release.Version + '...')
        Receive-DEHttps $release.Artifact.url $release.Artifact.bytes $archive 300 | Out-Null
        $installed = Install-DesignEditorArchive -ArchivePath $archive -InstallRoot $root -Version $release.Version -Architecture $arch -Sha256 $release.Artifact.sha256 -Bytes $release.Artifact.bytes
        return [pscustomobject]@{ Version = $installed.Version; Changed = $true; Status = 'installed' }
    } finally {
        try { if ($temporary -and [IO.Directory]::Exists($temporary)) { Remove-Item -LiteralPath $temporary -Recurse -Force } }
        finally { $lock.Dispose() }
    }
}

function Find-DEActiveProcess([string] $Root) {
    $prefix = [IO.Path]::GetFullPath((Join-Path $Root 'versions')) + [IO.Path]::DirectorySeparatorChar
    # Match only executables within this owned installation, not a PID/port or
    # generic Electron image name. Never stop processes from this function.
    foreach ($process in [Diagnostics.Process]::GetProcesses()) {
        try {
            if ($process.MainModule.FileName.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { return $true }
        } catch { continue } finally { $process.Dispose() }
    }
    return $false
}

function Start-DEDesktop([string] $Root, $State, [string] $Project) {
    $executable = Assert-DEPlainPath (Join-Path (Join-Path $Root $State.directory) $State.executable)
    Assert-DEExecutable $executable $State.arch
    $start = [Diagnostics.ProcessStartInfo]::new(); $start.FileName = $executable; $start.UseShellExecute = $false
    $start.WorkingDirectory = [IO.Path]::GetDirectoryName($executable)
    # A directory cannot contain a quote; trim the trailing separator before
    # quoting so Windows command-line parsing cannot consume the closing quote.
    $argument = '--design-editor-project=' + $Project
    $trailing = $argument.Length - $argument.TrimEnd([char]92).Length
    $start.Arguments = '"' + $argument + ('\' * $trailing) + '"'
    foreach ($name in @('NODE_OPTIONS','NODE_PATH','ELECTRON_RUN_AS_NODE','ELECTRON_OVERRIDE_DIST_PATH')) { $start.EnvironmentVariables.Remove($name) }
    $profile = Assert-DEPlainPath (Join-Path $Root 'user-data'); [void][IO.Directory]::CreateDirectory($profile)
    $start.EnvironmentVariables['DESIGN_EDITOR_CLI_LAUNCH'] = '1'; $start.EnvironmentVariables['DESIGN_EDITOR_CLI_USER_DATA'] = $profile
    # This launch already attempted the same update. The desktop can avoid a
    # duplicate cold check and resume its 30-minute cadence from this point.
    $start.EnvironmentVariables['DESIGN_EDITOR_UPDATE_CHECKED_AT'] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString([Globalization.CultureInfo]::InvariantCulture)
    $process = [Diagnostics.Process]::Start($start)
    try { Write-Host ('Opened Design Editor ' + $State.version + '.') } finally { $process.Dispose() }
}

function Register-DECommand([string] $InstallRoot, [switch] $SkipPath) {
    $root = Initialize-DEInstallRoot $InstallRoot
    $bin = Assert-DEPlainPath (Join-Path $root 'bin'); [void][IO.Directory]::CreateDirectory($bin)
    foreach ($item in @(@('design-editor.ps1',$script:DELauncherShim), @('design-editor.cmd',$script:DECommandShim))) {
        $destination = Assert-DEPlainPath (Join-Path $bin $item[0])
        if ([IO.File]::Exists($destination)) {
            if (([IO.FileInfo]$destination).Length -gt 65536 -or [IO.File]::ReadAllText($destination) -cne $item[1]) { throw 'A different command dispatcher already exists. It was left unchanged.' }
        } else {
            $file = [IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try { $bytes = [Text.UTF8Encoding]::new($false).GetBytes($item[1]); $file.Write($bytes,0,$bytes.Length); $file.Flush($true) } finally { $file.Dispose() }
        }
    }
    if (!$SkipPath) {
        $userPath = [string][Environment]::GetEnvironmentVariable('Path','User')
        if ($userPath.Length -gt 30000) { throw 'Your user PATH is too long to modify safely. Use the printed command path.' }
        if (@($userPath.Split(';') | Where-Object { $_.TrimEnd([char]92) -ieq $bin }).Count -eq 0) {
            [Environment]::SetEnvironmentVariable('Path',($userPath.TrimEnd(';') + ';' + $bin).TrimStart(';'),'User')
        }
        if (@($env:Path.Split(';') | Where-Object { $_.TrimEnd([char]92) -ieq $bin }).Count -eq 0) { $env:Path = $env:Path.TrimEnd(';') + ';' + $bin }
    }
    return Join-Path $bin 'design-editor.cmd'
}

function Invoke-DesignEditorCommand([string] $InstallRoot, [string[]] $Arguments = @()) {
    $root = Initialize-DEInstallRoot $InstallRoot
    if ($Arguments.Count -gt 1) { throw 'Use design-editor [project-folder], design-editor update, or design-editor --version.' }
    $action = if ($Arguments.Count) { $Arguments[0] } else { '.' }
    if ($action -in @('--help','-h')) { Write-Host 'Usage: design-editor [project-folder] | update | --version'; return }
    if ($action -eq '--version') { $current = Read-DECurrent $root; if (!$current) { throw 'Design Editor is not installed.' }; Write-Output $current.version; return }
    if ($action -eq 'update') { $updated = Update-DesignEditorInstallation $root; Write-Host ('Design Editor ' + $updated.Version + ' is ready. Existing windows are not restarted.'); return }
    if ($action.StartsWith('-')) { throw 'Unknown Design Editor option.' }
    try { $item = Get-Item -LiteralPath $action -ErrorAction Stop }
    catch { throw 'Choose an existing project folder.' }
    if (!$item.PSIsContainer -or $item.PSProvider.Name -ne 'FileSystem') { throw 'Choose an existing project folder.' }
    $project = $item.FullName
    $launchLockFile = Assert-DEPlainPath (Join-Path $root '.launch.lock')
    try { $launchLock = [IO.File]::Open($launchLockFile,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
    catch { throw 'Design Editor is already starting. Please wait.' }
    try {
        if (Find-DEActiveProcess $root) { Write-Host 'Design Editor is already open. Close it before starting another version or project; your current work has not been changed.'; return }
        try { Update-DesignEditorInstallation $root | Out-Null }
        catch { if (!(Read-DECurrent $root)) { throw }; Write-Warning 'Could not update. Opening the installed version; run design-editor update to retry.' }
        $current = Read-DECurrent $root; if (!$current) { throw 'Design Editor is not installed.' }
        Start-DEDesktop $root $current $project
    } finally { $launchLock.Dispose() }
}

try {
    if (!$env:LOCALAPPDATA) { throw 'Windows Local App Data is unavailable.' }
    $root = Join-Path $env:LOCALAPPDATA 'Programs/DesignEditorBeta'
    Write-Host 'Preparing Design Editor. This beta is not code-signed; Windows security rules still apply.'
    $result = Update-DesignEditorInstallation $root
    $command = Register-DECommand $root
    Write-Host ('Design Editor ' + $result.Version + ' is installed.')
    Write-Host 'Run: design-editor .  (Open a new terminal if the command is not found.)'
    Write-Host ('Command location: ' + $command)
} catch { Write-Error $_.Exception.Message; throw }
}
