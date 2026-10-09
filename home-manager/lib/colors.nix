{ lib }:
{
  # "#a48cf2" -> "164,140,242", the form Konsole and Plasma colour files use.
  rgb =
    hex:
    lib.concatMapStringsSep ","
      (i: toString (lib.fromHexString (builtins.substring i 2 (lib.removePrefix "#" hex))))
      [
        0
        2
        4
      ];
}
