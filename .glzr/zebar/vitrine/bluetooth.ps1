# Zebar exposes no bluetooth provider (checked against the v3.3.1 type definitions --
# audio, battery, cpu, date, disk, glazewm, host, ip, keyboard, komorebi, media,
# memory, network, systray, weather), so the bar shells out for this one value.
#
# Emits a single line: "<radioPresent>|<connectedCount>|<names>|<batteries>|<connected>",
# e.g. "1|1|MX Keys Mini;EDIFIER W800BT Pro|95;80|1;0". All three trailing lists are
# ';'-joined and index-aligned (names[i] <-> batteries[i] <-> connected[i]) since a
# device's FriendlyName can legitimately contain a comma, so that couldn't be used as
# the delimiter without risking a false split. Note a device can show connected=0 with
# a non-blank battery slot (the EDIFIER example above) -- that's its last-known
# reading from before it disconnected, not a live value; see signal 1's staleness note
# below for why it must never be allowed to drive the connected flag.
#
# <connectedCount> counts only devices flagged connected=1, not every present device --
# see the per-device-type detection below. It drives the bar's icon and dimming, so it
# has to reflect what's actually linked right now, not everything paired.
#
# Devices are grouped by DEVPKEY_Device_ContainerId, not FriendlyName or InstanceId
# prefix. A single physical peripheral is scattered across many PnP nodes -- an MX
# Keys Mini enumerates 9x as separate BTHLE\DEV_* nodes, and a classic headset like
# the EDIFIER below additionally registers one PnP node per Bluetooth profile it
# negotiates (AVRCP transport, SPP/serial, Hands-Free AG, ...). Windows assigns every
# node belonging to the same physical device the same ContainerId regardless of which
# bus or device Class it landed under, which is exactly the join key needed to
# reassemble "everything belonging to this headset" and pull whichever sibling node
# happens to carry the battery reading. FriendlyName-based dedup (the earlier
# approach) missed this: it only ever saw the primary BTHENUM\DEV_*/BTHLE\DEV_* node,
# and for the EDIFIER that primary node never carries battery -- see signal 1 below.
#
# Get-PnpDevice's Status/Problem can't tell "actually connected" apart from "paired,
# in range, powered off" for classic Bluetooth peripherals -- Windows sets
# DEVPKEY_DeviceContainer_AlwaysShowDeviceAsConnected on these, which keeps Status =
# OK either way (verified live: a headset that was powered off reported Status OK /
# Problem CM_PROB_NONE, identical to an actually-connected keyboard). Two properties
# were tried as a live proxy, and each turned out reliable for a different half of the
# problem -- hence the per-device-type split below rather than a single shared check:
#
# 1. The Bluetooth battery-level DEVPKEY (see $BATTERY_KEY below): populated on
#    whichever PnP node is actually receiving the reading, which is device- and
#    profile-dependent -- for the MX Keys Mini (BLE HID) it's the primary BTHLE\DEV_*
#    node; for the EDIFIER W800BT Pro (classic headset) it's neither the primary
#    BTHENUM\DEV_* node nor its AVRCP transport nodes (verified those stay empty even
#    while actively playing audio) but its "... Hands-Free AG" node (InstanceId
#    BTHENUM\{0000111e-...}, Device Class "System", not "Bluetooth"). That part is
#    still fine and is why grouping by ContainerId is needed at all -- but this
#    property is STALE on that node: verified live that it kept reporting the
#    headset's last battery reading (80) well after actually disconnecting it, while
#    the audio endpoints below dropped out immediately. So battery presence is only
#    trustworthy as a connection signal for devices with no audio profile at all
#    (nothing else re-reads/clears it for them); for audio-capable devices it is
#    display-only, gated on signal 2 below actually being true.
# 2. Audio endpoint presence: a Bluetooth device's render/capture endpoints
#    (SWD\MMDEVAPI\...) only exist while it's actually linked over A2DP/HFP -- Windows
#    creates them on connect and removes them on disconnect (verified live), unlike
#    signal 1. Matched by FriendlyName substring against the device name (Windows
#    names endpoints after the paired device, e.g. "Headphones (3- EDIFIER W800BT
#    Pro)") rather than an exact ContainerId join: a first version queried every
#    audio endpoint's ContainerId individually to do the exact join, which cost ~14
#    extra Get-PnpDeviceProperty round-trips (~400-500ms each -- verified this is a
#    real per-call CIM cost, not just process spawn) for zero behavioral difference
#    from the cheap name match in every case tested. "Is this device audio-capable at
#    all" (independent of current connection) is answered for free from data already
#    in hand: AVRCP/Hands-Free/A2DP profile sub-nodes are paired-time-static (present
#    in the sibling group even while the device is off, same as the primary node), so
#    their names alone -- no extra property query -- settle it.
#
# So: audio-capable devices (a sibling node name matching Avrcp/Hands-Free/A2DP/
# Headset) are judged connected purely by a currently-present matching audio
# endpoint; everything else falls back to battery presence, the only signal
# available for them. A device with neither signal isn't dropped from the output --
# it still shows up flagged connected=0 instead of silently vanishing -- and
# connected devices sort first so the bar's default (unclicked) view lands on one of
# them rather than whichever paired-but-off device enumerated first.
#
# ContainerId {00000000-0000-0000-ffff-ffffffffffff} is Windows' sentinel for "no
# real container assigned" (verified: shared by the onboard Realtek speakers/mic AND
# by an orphan "Standard Serial over Bluetooth link" COM port node with no relation to
# either device) -- it must be excluded explicitly, or unrelated nodes that all lack a
# real container get grouped together and falsely cross-match on signal 2.
#
# -InstanceId wildcards are used rather than a -match regex on purpose: the regex form
# has to survive Zebar -> cmd -> PowerShell quoting and silently matched nothing when
# tested, while wildcards pass through intact.
#
# Known limitations:
# - "radio off" and "radio on, nothing connected" both report radio=1 with a device
#   count of 0, because Windows keeps the enumerator device present either way.
#   Distinguishing them needs the async WinRT Radio API, which costs more per poll
#   than the icon is worth. The bar therefore dims the glyph on 0 rather than
#   claiming the radio is off.
# - A genuinely connected device with no audio profile AND no Bluetooth battery
#   reporting on any of its nodes (e.g. a plain BT mouse with no battery service)
#   will still show as "not connected" -- there's no live link-state DEVPKEY to fall
#   back to for that case without the same WinRT cost noted above.
# - The audio-endpoint match (signal 2) is a FriendlyName substring check, not an
#   ID-based join -- good enough in practice since Windows names endpoints after the
#   paired device, but two paired devices with one name embedded in the other could
#   theoretically cross-match.
$ErrorActionPreference = 'SilentlyContinue'

# Property lookups go through Get-CimInstance + Invoke-CimMethod directly instead of
# Get-PnpDevice/Get-PnpDeviceProperty. Those cmdlets are CDXML wrappers around this
# same Win32_PnPEntity WMI class (confirmed from the module's .cdxml: every call
# re-resolves the target instance by DeviceID via a fresh WQL lookup before invoking
# GetDeviceProperties) -- verified that per-call cost at ~400-500ms regardless of
# payload size, dominating the poll (9 nodes = ~4s just in that overhead, the single
# largest cost this script had). Doing ONE bulk Get-CimInstance query up front and
# calling Invoke-CimMethod directly on the already-resolved CimInstance objects skips
# that repeated lookup -- verified this drops the same 9-node property-fetch step
# from ~4s to well under 0.5s, an order of magnitude, since the instance is already
# in hand and each call is then just the actual property read.
$BATTERY_KEY = '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2'
$CONTAINER_KEY = 'DEVPKEY_Device_ContainerId'
$NULL_CONTAINER_ID = '{00000000-0000-0000-ffff-ffffffffffff}'

# No PNPClass filter on purpose: a device's own sub-nodes land in whatever class
# Windows assigns that specific function (verified: EDIFIER's Hands-Free AG node,
# the one carrying its battery reading, is class "System"; audio endpoints are
# "SWD\MMDEVAPI\..." rather than any Bluetooth-named class). DeviceID prefix is what
# actually identifies what a node is: remote peripherals and their profile/service
# sub-nodes always enumerate under BTHENUM\ or BTHLE\; the local adapter/radio
# hardware shows up under its own bus (USB\VID_..., or BTH\MS_* for the software
# enumerator/radio); audio endpoints under SWD\MMDEVAPI\ -- all fetched from the same
# single unfiltered query rather than three separate calls (Win32_PnPEntity covers
# every PnP-enumerated device on the system regardless of bus, audio endpoints
# included -- verified).
$allPresent = @(Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { $_.Status -eq 'OK' })
$radio = @($allPresent | Where-Object { $_.DeviceID -like 'BTH\MS_BTHBRB*' }).Count
$peripheralNodes = @($allPresent |
  Where-Object { $_.DeviceID -like 'BTHENUM\*' -or $_.DeviceID -like 'BTHLE\*' })
$audioEndpointNames = @($allPresent |
  Where-Object { $_.DeviceID -like 'SWD\MMDEVAPI\*' } | Select-Object -ExpandProperty Name)

$nodeInfo = $peripheralNodes | ForEach-Object {
  $result = Invoke-CimMethod -InputObject $_ -MethodName GetDeviceProperties `
    -Arguments @{ devicePropertyKeys = @($BATTERY_KEY, $CONTAINER_KEY) }
  $props = $result.deviceProperties
  [PSCustomObject]@{
    Name        = $_.Name
    IsPrimary   = ($_.DeviceID -like 'BTHENUM\DEV_*' -or $_.DeviceID -like 'BTHLE\DEV_*')
    ContainerId = ($props | Where-Object KeyName -eq $CONTAINER_KEY).Data
    Battery     = ($props | Where-Object KeyName -eq $BATTERY_KEY).Data
  }
}

$devices = @(
  $nodeInfo | Where-Object { $_.ContainerId -and $_.ContainerId -ne $NULL_CONTAINER_ID } |
    Group-Object ContainerId |
    ForEach-Object {
      # Prefer the primary enumerator node's name ("EDIFIER W800BT Pro") over a
      # profile sub-node's ("EDIFIER W800BT Pro Hands-Free AG") when both exist.
      $primary = $_.Group | Where-Object IsPrimary | Select-Object -First 1
      $name = if ($primary) { $primary.Name } else { ($_.Group | Select-Object -First 1).Name }

      # Whichever sibling node in this container actually carries the battery
      # reading (device- and profile-dependent, see header). Explicitly falling
      # back to '' rather than leaving this $null matters: assigning an empty
      # pipeline's result to a variable and dropping that into a PSCustomObject
      # property produces a property PowerShell's dotted member enumeration
      # (`$devices.Battery`) silently omits instead of counting as a null slot --
      # confirmed this would desync the names/batteries/connected index alignment
      # for any device without a reading that isn't last in the list.
      $found = @($_.Group.Battery | Where-Object { $null -ne $_ -and $_ -ne '' })
      $battery = if ($found.Count -gt 0) { $found[0] } else { '' }

      # Sibling node names already in hand -- no extra query, see header note.
      $isAudioCapable = @($_.Group.Name | Where-Object { $_ -match 'Avrcp|Hands-?Free|A2DP|Headset' }).Count -gt 0

      $connected = if ($isAudioCapable) {
        # Audio-capable device: battery is known stale post-disconnect for at least
        # one real headset, so it's excluded from this decision entirely here --
        # live endpoint presence is the only signal trusted.
        $namePattern = '*' + [System.Management.Automation.WildcardPattern]::Escape($name) + '*'
        @($audioEndpointNames | Where-Object { $_ -like $namePattern }).Count -gt 0
      } else {
        # No audio profile -- battery presence is the only signal available.
        $battery -ne ''
      }

      [PSCustomObject]@{
        Name      = $name
        Battery   = $battery
        Connected = if ($connected) { 1 } else { 0 }
      }
    } |
    Sort-Object -Property @{ Expression = { 1 - $_.Connected } }
)

$connectedCount = @($devices | Where-Object { $_.Connected -eq 1 }).Count

Write-Output ('{0}|{1}|{2}|{3}|{4}' -f $radio, $connectedCount, `
  ($devices.Name -join ';'), ($devices.Battery -join ';'), ($devices.Connected -join ';'))
