import Quickshell

// kome — quickshell entry point (ported from 43PR/dotfiles, MIT).
// One persistent shell mounts the volume OSD, the settings control centre,
// and the hot-corner triggers. The wallpaper picker stays on-demand via
// `kome-wallpaper picker`, so it is not mounted here.

ShellRoot {
    VolumeOsd {}
    SettingsWindow {}
    SettingsCornerTrigger {}
}
