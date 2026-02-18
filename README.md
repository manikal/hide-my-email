# Hide My Email Generator

Generate Apple **Hide My Email** addresses from the command line on macOS.

Uses AppleScript UI automation to drive System Settings — no private APIs, no cookies, no browser sessions.

## Demo

```bash
$ hme "Netflix"
✓ cobalt.coccyx0d@icloud.com (copied to clipboard)
```

## Requirements

- **macOS Tahoe** (26.x) — UI element paths are specific to this version
- **iCloud+ subscription** — Hide My Email is an iCloud+ feature
- **Accessibility permissions** — required for UI automation

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/manikal/hide-my-email.git
cd hide-my-email
```

### 2. Grant Accessibility permissions

`osascript` needs permission to control System Settings via UI automation.

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **"+"**
3. Press **⌘⇧G** and type `/usr/bin/osascript`
4. Toggle it **on**

> **Tip:** If you wrap this in a `.app` bundle, the app itself gets added instead — cleaner for distribution.

### 3. Add to PATH

```bash
# Option A: symlink (recommended)
ln -s "$(pwd)/hme" /usr/local/bin/hme

# Option B: alias in ~/.zshrc
alias hme='/path/to/hide-my-email/hme'
```

### 4. Run it

```bash
hme "MyLabel"
```

With an optional note:

```bash
hme "Shopping" "For online orders"
```

## Usage

```
hme <label> [note]

Arguments:
  label    Label for the email address (required)
  note     Optional note for the email address

Options:
  --help   Show usage information
```

The generated email address is:
- Printed to stdout with a ✓ confirmation
- Copied to your clipboard automatically

> You can also call the AppleScript directly: `osascript hide_my_email.applescript "MyLabel"`

## How it works

The script automates the following flow via macOS Accessibility (UI scripting):

1. Opens **System Settings → iCloud**
2. Clicks **Hide My Email** in the iCloud+ Features section
3. Clicks **Create New Address** (+)
4. Reads the generated email address
5. Fills in the label (and optional note)
6. Clicks **Continue** to save
7. Copies the email to your clipboard

No network calls, no private APIs — just the same UI flow you'd do manually.

## Advanced: direct AppleScript usage

If you prefer not to use the wrapper:

```bash
osascript hide_my_email.applescript "Twitter"
```

## Limitations

- **macOS version dependent** — UI element paths change between macOS versions. This is tested on Tahoe (26.x). Pull requests for other versions welcome.
- **~10 second runtime** — includes delays for UI elements to load.
- **Rate limited by Apple** — approximately 5 addresses per 30 minutes per iCloud family member.
- **Requires screen access** — System Settings must be visible (not suitable for headless/SSH sessions).
- **Window positioning** — the script sets System Settings to a fixed position (100, 100) and size (780×700) for reliable element targeting. Your window will be moved.

## Troubleshooting

| Problem | Solution |
|---|---|
| `"Can't get sheet 1..."` | Increase the `delay` values — your Mac may be slower to load the UI |
| `"Timed out waiting..."` | Make sure you're signed into iCloud with an active iCloud+ subscription |
| Script clicks the wrong button | System Settings window may have been resized. The script resets it, but if issues persist, try running from a fresh `System Settings` state (⌘Q first) |
| `"Not allowed assistive access"` | Grant Accessibility permissions (see Setup step 2) |

## License

MIT
