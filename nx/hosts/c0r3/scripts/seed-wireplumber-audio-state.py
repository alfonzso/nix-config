from pathlib import Path


STATE_DIR = Path.home() / ".local/state/wireplumber"


def set_values(path, section, updates, remove_keys=(), remove_prefixes=()):
    if path.exists():
        lines = path.read_text().splitlines()
    else:
        lines = []

    header = f"[{section}]"
    try:
        start = lines.index(header)
    except ValueError:
        if lines and lines[-1]:
            lines.append("")
        lines.append(header)
        start = len(lines) - 1

    end = len(lines)
    for idx in range(start + 1, len(lines)):
        if lines[idx].startswith("[") and lines[idx].endswith("]"):
            end = idx
            break

    existing = {}
    for idx in range(start + 1, end):
        key, sep, _ = lines[idx].partition("=")
        if sep:
            existing[key] = idx

    remove_indexes = sorted((
        idx
        for key, idx in existing.items()
        if key in remove_keys
        or any(key.startswith(prefix) for prefix in remove_prefixes)
    ), reverse=True)
    for idx in remove_indexes:
        del lines[idx]
        end -= 1

    existing = {}
    for idx in range(start + 1, end):
        key, sep, _ = lines[idx].partition("=")
        if sep:
            existing[key] = idx

    for key, value in updates.items():
        line = f"{key}={value}"
        if key in existing:
            lines[existing[key]] = line
        else:
            lines.insert(end, line)
            end += 1

    path.write_text("\n".join(lines) + "\n")


def main():
    STATE_DIR.mkdir(parents=True, exist_ok=True)

    set_values(
        STATE_DIR / "default-profile",
        "default-profile",
        {
            "alsa_card.pci-0000_00_1f.3": "pro-audio",
        },
        remove_keys=("alsa_card.pci-0000_01_00.1",),
    )

    set_values(
        STATE_DIR / "default-nodes",
        "default-nodes",
        {},
        remove_prefixes=("default.configured.audio.sink",),
    )


if __name__ == "__main__":
    main()
