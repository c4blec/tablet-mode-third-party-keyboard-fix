# tablet mode third-party keyboard fix

initially put together for the asus rog flow z13 2025

## problem it solves

some windows devices have a detachable (tablet)/disableable (2-in-1) keyboard, which when removed/disabled switches windows into tablet mode, which slightly tweaks how the windows ui looks and functions. you can disable some tablet mode changes manually by:
- settings > bluetooth & devices > pen & windows ink > handwriting panel settings > when i tap a…
- settings > personalization > taskbar > system tray icons > touch keyboard/show touch keyboard icon
- settings > time & language > typing > touch keyboard > show the touch keyboard

but some behaviors will still be unaffected:
- browser touch mode (unless explicitly disabled in browser settings)
- website tablet format (some sites will continue to show tablet formatting)

plugging in a third-party keyboard (e.g. keychron, logitech, razer, etc) does not return windows to desktop mode.

i assume most users are either not bothered by the above, or at least are satisfied just disabling the according settings.

but if you are like me (use tablet mode as needed, when no keyboard is attached), a problem arises when wanting to switch back and forth between modes. having to manually switch by going through the settings, or by script to change the according registry entries can get annoying. and when you notice it, it stunts flow.

## what it does

a powershell script that does the following:
1. gets and remembers status (so the script doesn't send redundant mode changes)
   1. if device present/connected or absent/disconnected
   1. last `convertibleslatemode` (the registry entry that dictates desktop or tablet mode)
1. monitors for (waits for the according events)
   1. change to hids (i.e. any time a device is connected/disconnected)
   1. monitors for change to `convertibleslatemode` (i.e. when windows automatically defaults to tablet mode on: startup, sleep, screen dim, etc)
1. on script startup
   1. check for hid
      1. if present = desktop mode (change `convertibleslatemode` = 1)
      1. if absent = tablet mode (change `convertibleslatemode` = 0)
1. if change to hids
   1. check for hid
      1. if connected = desktop mode
      1. if disconnected = tablet mode
1. if change to `convertibleslatemode`
   1. check for hid
      1. if present = desktop mode
      1. if absent = do nothing (lets windows revert back to tablet mode)

## how to use

### device setup

1. save `KbConvertSlateMode.ps1` anywhere on your computer
1. open `device manager`
   1. start menu > enter `device manager` > select `device manager (control panel)`, it should open a new window
   1. OR keyboard: windows + r > enter `devmgmt.msc` > select `ok`
1. inside `device manager`, find the devices you want to use (for this example i'm just going to illustrate for keyboards, but you can pretty much use any other device you want)
1. expand `keyboards`, then double-click the appropriate `hid keyboard device`, it should open a new window (might have to disconnect/reconnect to see which device it actually is)
   1. inside the new `hid keyboard device` window, select the tab `details`
   1. under `property`, change the dropdown selection to `hardware ids`
   1. entries below should change to something like `HID\VID_0123&PID_0123&REV_0123&MI_04&Col01`
      1. all you actually need is the `HID\VID_0123&PID_0123` part
1. open `KbConvertSlateMode.ps1` in notepad
   1. edit the `HID/VID_…` line(s) accordingly (feel free to remove the second line if you only want the script to detect the one device)

### automation setup

1. save `KbConvertSlateMode.xml` anywhere on your computer
1. open `task scheduler`
   1. start menu > enter `task scheduler` > select `task scheduler (system)`, it should open a new window
   1. OR keyboard: windows + r > enter `taskschd.msc` > select `ok`
1. inside `task scheduler`, to the right under the `actions` submenu, select `import task…`
1. find wherever you saved `KbConvertSlateMode.xml`, open it, it should open a new window
   1. inside the new `create task` window, under `security options`, select the button `change user or group…`
      1. under `enter the object…`, type in your user account name
         1. if you don't know what it is, open `file explorer` in a new window, go to `C:\Users` (your user account name should be a folder in there)
      1. select the button `check names`, it should correct it accordingly: `pcname\username`
      1. after it successfully corrects, select the button `ok`
   1. back at the `create task` window, select the tab `actions`
      1. double-click the `start a program action`
      1. inside the new `edit action` window, select the field `add arguments (optional)`
         1. input: `-WindowStyle Hidden -ExecutionPolicy Bypass -File "ABCXYZ\KbConvertSlateMode.ps1"`
         1. replace ABCXYZ = directory you saved the `.ps1` file (NOT the `.xml`)
         1. select the button `ok`
      1. back inside the `create task` window, select the button `ok`

### run the script

1. just `restart` your pc
1. OR back inside `task scheduler`, scroll down until you find the according `KbConvertSlateMode` task
   1. right-click to open the context menu, select the option `run`

# that's it

peace
