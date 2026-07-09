# c0r3 Known Issues

## Monitor-jack audio depends on HDMI audio EDID

### Symptom

- Video works on the HDMI monitor, but no sound comes from a soundbar connected to the monitor's 3.5mm jack.
- Sunshine/Moonlight audio may still work because that audio is streamed to the client, not played through the local monitor jack.
- `/proc/asound/card*/eld*` may show `monitor_present 0` or `eld_valid 0` for NVIDIA HDMI outputs.

### Cause

The monitor's 3.5mm jack receives audio from HDMI. If the host uses a generic forced EDID for headless Sunshine, the EDID may not advertise HDMI audio, so ALSA/PipeWire do not expose a useful NVIDIA HDMI sink.

`nx/hosts/c0r3/modules/hardware/nvidia.nix` installs `nx/hosts/c0r3/firmware/edid/1920x1080-audio.bin`, a custom EDID with CTA-861 basic audio and 2-channel LPCM support. It was generated with [edid.build](https://edid.build/). NVIDIA HDMI audio should not be forced to `off` in WirePlumber state.

### Useful diagnostics

```bash
aplay -l
wpctl status
pactl list sinks short
rg -n "monitor_present|eld_valid|monitor_name" /proc/asound/card*/eld*
```

Expected healthy state after reboot/rebuild:

- NVIDIA HDMI card exposes an HDMI/DisplayPort sink.
- ELD for the connected HDMI output is valid.
- KDE can select the HDMI monitor output for local soundbar playback.

## Analog audio can disappear after profile/mixer reset

### Symptom

- No sound from speakers connected directly to the PC analog 3.5mm output.
- KDE/PipeWire may still show `Built-in Audio Pro` as the active output.
- Applications may appear correctly routed to `ALC892 Analog`, but no sound is heard.

### Hardware context

- Built-in audio: `HDA Intel PCH` / `Realtek ALC892`
- PipeWire device name: `alsa_card.pci-0000_00_1f.3`
- Working sink: `alsa_output.pci-0000_00_1f.3.pro-output-0`
- NVIDIA HDMI audio is used for the monitor's 3.5mm jack when the soundbar is connected to the monitor.

### Declarative workaround in Nix

`nx/hosts/c0r3/default.nix` forces the built-in analog card profile:

- built-in audio card -> `pro-audio`

This makes PipeWire expose `Built-in Audio Pro` reliably for the motherboard analog output.

### Runtime issue found

Even when PipeWire is correct, ALSA hardware mixer can mute the actual card:

```text
Simple mixer control 'Master',0
  Mono: Playback 0 [0%] [-64.00dB] [off]
```

In that case PipeWire routing looks healthy, but the hardware output is muted.

### Fix command

Run:

```bash
amixer -c 1 set Master 100% unmute
```

Then test sound:

```bash
python3 - <<'PY' | pw-play --raw --rate 48000 --channels 2 --format s16 -
import math, struct, sys
rate = 48000
seconds = 2
freq = 660
amp = 0.22
for n in range(rate * seconds):
    sample = int(32767 * amp * math.sin(2 * math.pi * freq * n / rate))
    sys.stdout.buffer.write(struct.pack("<hh", sample, sample))
PY
```

### Useful diagnostics

```bash
wpctl status
pactl info
pactl list sinks short
pactl list sink-inputs
pw-cli enum-params 50 Profile
wpctl inspect 50
amixer -c 1
```

Expected healthy state:

- default sink: `alsa_output.pci-0000_00_1f.3.pro-output-0`
- active sink: `Built-in Audio Pro`
- built-in card profile: `pro-audio`
- ALSA `Master`: `100%` and `[on]`

