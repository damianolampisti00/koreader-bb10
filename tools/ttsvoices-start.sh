#!/bin/sh
# Mount all the installed Nuance TTS voices, read-only, where BB10 mounts its own voice
# (/usr/tts/nuance/ve/data/<LANG>/<voice>): the system mounts only the one chosen in its
# settings, KOReader's read aloud can then use the voice of each book's language.
# Root only (BB10 boot addon: /var/addons/ttsvoices/init/start.sh).
# Undo: rm -r /var/addons/ttsvoices, then reboot.
for links in /apps/sys.data.nuance_ve.*/assets/links; do
    pkg=${links%/assets/links}
    # e.g. "mount:assets/data/fs1.rcfs:/usr/tts/nuance/ve/data/ENU/ava:rcfs"
    while IFS=: read kind image target fstype; do
        [ "$kind" = mount ] && [ "$fstype" = rcfs ] || continue
        case $target in /usr/tts/nuance/ve/data/*/*) ;; *) continue ;; esac
        # Already there (mounted by the system, or by an earlier run)?
        [ -e "$target/." ] && [ -n "$(ls "$target" 2>/dev/null)" ] && continue
        mount -t rcfs -r "$pkg/$image" "$target"
    done < "$links"
done
