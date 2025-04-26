{
  lib,
  stdenv,
  buildDotnetModule,
  dotnetCorePackages,
  fontconfig,
  xorg,
  miniaudio,
}:
let
  fs = lib.fileset;
  fp = lib.path;
  runtime =
    if (stdenv.hostPlatform.isLinux) then
      if (stdenv.hostPlatform.isx86_64) then
        "linux-x64"
      else if (stdenv.hostPlatform.isAarch64) then
        "linux-arm64"
      else
        null
    else if stdenv.hostPlatform.isDarwin then
      "osx"
    else
      null;
in
buildDotnetModule {
  pname = "OpenUtau";
  version = "0-git";

  src = fs.toSource {
    root = ./.;
    fileset = lib.pipe ./. [
      (lib.flip fs.difference (
        fs.unions [
          # Exclude
          (fs.maybeMissing ./git)
          ./.github
          ./cpp
          ./py
          ./flake.lock
          ./deps.json
          ./appveyor.yml
          ./crowdin.yml
          (fs.fileFilter (
            f:
            lib.foldr (a: b: f.hasExt a || b) false [
              # All generated files
              "o"
              "so"
              "dylib"
              "dll"
              # All Nix files
              "nix"
              # All Python files
              "py"
            ]
          ) ./.)
          (fs.fileFilter (f: lib.hasPrefix "." f.name) ./.) # All hidden files
        ]
      ))

      lib.singleton
      (lib.concat (
        lib.flatten [
          # Include
          (lib.optional (fp.subpath.isValid runtime) (
            fs.fileFilter (f: f.hasExt (lib.removePrefix "." stdenv.hostPlatform.extensions.sharedLibrary)) (
              lib.path.append ./runtimes runtime
            )
          )) # Shared libs
        ]
      ))
      fs.unions
    ];
  };

  dotnet-sdk = dotnetCorePackages.sdk_9_0;
  dotnet-runtime = dotnetCorePackages.dotnet_8.aspnetcore;

  projectFile = "OpenUtau/OpenUtau.csproj";
  nugetDeps = ./deps.json;

  runtimeDeps = [
    xorg.libX11
    xorg.libICE
    xorg.libSM
    miniaudio
  ];

  buildInputs = [
    fontconfig
  ];

  # TODO: Verify this
  # socket cannot bind to localhost on darwin for tests
  # doCheck = !stdenv.hostPlatform.isDarwin;

  postInstall = lib.optionalString (fp.subpath.isValid runtime) ''
    install -Dm644 runtimes/${runtime}/native/libworldline${stdenv.hostPlatform.extensions.sharedLibrary} "$out"/lib/OpenUtau/
  '';

  meta = {
    description = "Open source singing synthesis platform and UTAU successor";
    homepage = "http://www.openutau.com/";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ lord-valen ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "OpenUtau";
  };

  meta = {
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      # deps
      binaryBytecode
      # worldline resampler
      binaryNativeCode
    ];
  };
}
