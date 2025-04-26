{
  pkgs ? import <nixpkgs> { },
  lib ? import <nixpkgs/lib> { },
}:
{
  env = [
    {
      name = "NIX_LD_LIBRARY_PATH";
      value = lib.makeLibraryPath [
        pkgs.icu
        pkgs.stdenv.cc.cc.lib
        pkgs.fontconfig
        pkgs.xorg.libX11
        pkgs.xorg.libICE
        pkgs.xorg.libSM
      ];
    }
  ];
  packages = [
    (
      with pkgs.dotnetCorePackages;
      combinePackages [
        sdk_8_0
        sdk_9_0
      ]
    )
    pkgs.nuget-to-json
    pkgs.fontconfig
  ];
  commands = [
    {
      name = "fetch-deps";
      help = "Produce deps.json from nuget packages";
      command = ''
        TMP=$(mktemp -d)

        dotnet restore --packages "$TMP" --use-current-runtime $PRJ_ROOT/OpenUtau/OpenUtau.csproj
        nuget-to-json "$TMP" > "$PRJ_ROOT"/deps.json

        rm -r "$TMP"
      '';
    }
    {
      name = "run";
      help = "Run OpenUtau";
      command = ''
        LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
        dotnet run --project $PRJ_ROOT/OpenUtau/OpenUtau.csproj
      '';
    }
  ];
}
