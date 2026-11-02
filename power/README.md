# Power settings

`cpu-turbo-cap.service` is a system unit that `restore-power` installs as
`/etc/systemd/system/cpu-turbo-cap.service`. At boot it writes `80` to
`/sys/devices/system/cpu/intel_pstate/max_perf_pct`, which caps the CPU at
about 80% of its top turbo clock (3.7 GHz on an i7-11800H instead of 4.6 GHz).
The unit does nothing on a machine without the `intel_pstate` driver.

The last fifth of the clock is where the heat is. Uncapped, a single busy core
sits at 98 °C with the fan at full speed; capped, the same load runs at about
60 °C and the fan stays off. `restore-power` also selects the `balanced`
power profile, because the `performance` profile pins the energy preference
and the firmware fan curve to their loudest setting and power-profiles-daemon
remembers that choice across reboots.

Lift the cap for one session with
`echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct`; the
unit restores it at the next boot.
