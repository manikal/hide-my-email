-- hide_my_email.applescript
-- Generate Apple Hide My Email addresses from the command line.
-- Requires: macOS Tahoe (26+), iCloud+ subscription, Accessibility permissions for osascript.
--
-- Usage:
--   osascript hide_my_email.applescript "MyLabel"
--   osascript hide_my_email.applescript "MyLabel" "Optional note"
--   osascript hide_my_email.applescript --help

on run argv
  -- Parse arguments
  if (count of argv) is 0 then
    my showUsage()
    error "No label provided. Run with --help for usage." number 1
  end if

  set firstArg to item 1 of argv
  if firstArg is "--help" or firstArg is "-h" then
    return my showUsage()
  end if
  
  set emailLabel to firstArg
  set emailNote to ""
  if (count of argv) ≥ 2 then
    set emailNote to item 2 of argv
  end if
  
-- Step 1: Quit System Settings if already open, then open to iCloud
  tell application "System Events"
    if exists process "System Settings" then
      try
        tell application "System Settings" to quit
      end try
      delay 1
    end if
  end tell
  do shell script "open 'x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?iCloud'"

  -- Wait for window to appear and set fixed position/size
  tell application "System Events"
    repeat 20 times
      try
        if exists process "System Settings" then
          if (count of windows of process "System Settings") ≥ 1 then exit repeat
        end if
      end try
      delay 0.5
    end repeat
    tell process "System Settings"
      set position of window 1 to {100, 100}
      set size of window 1 to {780, 700}
      set frontmost to true
    end tell
  end tell
  delay 2
  
  -- Step 2: Find and click "Hide My Email" in iCloud+ Features
  tell application "System Events"
    tell process "System Settings"
      set contentScroll to scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
      -- Find the iCloud+ Features group by scanning for its label
      set featGroup to missing value
      repeat with elem in UI elements of contentScroll
        try
          if (class of elem is group) and (value of static text 1 of elem is "iCloud+ Features") then
            set featGroup to elem
            exit repeat
          end if
        end try
      end repeat
      if featGroup is missing value then
        error "Could not find iCloud+ Features section."
      end if
      -- Hide My Email is button 5 in the 2x3 grid (row 2, column 2)
      click button 5 of featGroup
    end tell
  end tell
  
  -- Wait for Hide My Email sheet to appear
  tell application "System Events"
    tell process "System Settings"
      repeat 30 times
        try
          if (count of sheets of window 1) ≥ 1 then exit repeat
        end try
        delay 0.5
      end repeat
      if (count of sheets of window 1) < 1 then
        error "Timed out waiting for Hide My Email panel to open."
      end if
    end tell
  end tell
  -- Wait for the HME list panel to fully load (scroll area + Create New Address button)
  tell application "System Events"
    tell process "System Settings"
      repeat 30 times
        try
          set _btn to button "Create New Address" of group 1 of group 1 of group 1 of UI element 1 of scroll area 1 of sheet 1 of window 1
          exit repeat
        end try
        delay 0.5
      end repeat
    end tell
  end tell

  -- Step 3: Click "Create New Address" (+) button
  tell application "System Events"
    tell process "System Settings"
      set mainGroup to group 1 of group 1 of group 1 of UI element 1 of scroll area 1 of sheet 1 of window 1
      click button "Create New Address" of mainGroup
    end tell
  end tell

  -- Wait for the create form to load: poll all sheets until email field appears
  set createSheetIndex to 0
  tell application "System Events"
    tell process "System Settings"
      repeat 30 times
        try
          repeat with i from 1 to (count of sheets of window 1)
            try
              set _base to group 1 of UI element 1 of scroll area 1 of sheet i of window 1
              set _email to value of static text 1 of UI element 5 of group 1 of _base
              if _email is not "" then
                set createSheetIndex to i
                exit repeat
              end if
            end try
          end repeat
          if createSheetIndex > 0 then exit repeat
        end try
        delay 0.5
      end repeat
      if createSheetIndex is 0 then
        error "Timed out waiting for the Create New Address dialog."
      end if
    end tell
  end tell

  -- Step 4: Read generated email, fill in label/note, click Continue
  set generatedEmail to ""
  tell application "System Events"
    tell process "System Settings"
      set createBase to group 1 of UI element 1 of scroll area 1 of sheet createSheetIndex of window 1
      set mainContent to group 1 of createBase

      -- The email is static text inside UI element 5 (group with copy button + email text)
      set generatedEmail to value of static text 1 of UI element 5 of mainContent

      -- Step 5: Fill in label (text field in UI element 8)
      set labelField to text field 1 of UI element 8 of mainContent
      set focused of labelField to true
      delay 0.3
      set value of labelField to emailLabel
      delay 0.3

      -- Step 6: Fill in note (optional, text area in UI element 11)
      if emailNote is not "" then
        set noteField to text area 1 of UI element 11 of mainContent
        set focused of noteField to true
        delay 0.3
        set value of noteField to emailNote
        delay 0.3
      end if

      -- Step 7: Click Continue (in the navigation group)
      set navGroup to group 2 of createBase
      click button "Continue" of group 2 of group 1 of navGroup
    end tell
  end tell
  delay 1
  
  -- Step 8: Copy email to clipboard
  do shell script "echo " & quoted form of generatedEmail & " | tr -d '\\n' | pbcopy"

  -- Step 9: Close System Settings
  delay 1.5
  try
    tell application "System Settings" to quit
  end try

  return generatedEmail
end run

on showUsage()
  set usage to "Hide My Email Generator" & linefeed & linefeed
  set usage to usage & "Usage:" & linefeed
  set usage to usage & "  osascript hide_my_email.applescript <label> [note]" & linefeed & linefeed
  set usage to usage & "Arguments:" & linefeed
  set usage to usage & "  label    Label for the email address (required)" & linefeed
  set usage to usage & "  note     Optional note for the email address" & linefeed & linefeed
  set usage to usage & "Examples:" & linefeed
  set usage to usage & "  osascript hide_my_email.applescript \"Netflix\"" & linefeed
  set usage to usage & "  osascript hide_my_email.applescript \"Shopping\" \"For online orders\"" & linefeed & linefeed
  set usage to usage & "The generated email is copied to your clipboard automatically." & linefeed & linefeed
  set usage to usage & "Requirements:" & linefeed
  set usage to usage & "  - macOS Tahoe (26.x)" & linefeed
  set usage to usage & "  - Active iCloud+ subscription" & linefeed
  set usage to usage & "  - Accessibility permissions for osascript or the wrapping .app"
  return usage
end showUsage