# srsRAN Project - Open source O-RAN 5G CU/DU (gNB)
# https://github.com/srsran/srsRAN_Project
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  fftwFloat,
  mbedtls,
  boost,
  lksctp-tools,
  yaml-cpp,
  uhd,
  zeromq,
  libbladeRF,
  gtest,
  # Build options
  enableUHD ? true,
  enableZeroMQ ? true,
  enableAvx ? stdenv.hostPlatform.avxSupport,
  enableAvx2 ? stdenv.hostPlatform.avx2Support,
  enableAvx512 ? stdenv.hostPlatform.avx512Support,
}:

stdenv.mkDerivation rec {
  pname = "srsran-project";
  version = "25.10";

  src = fetchFromGitHub {
    owner = "srsran";
    repo = "srsRAN_Project";
    rev = "release_25_10";
    # Run `nix build` to get the correct hash on first build
    hash = "sha256-F8ik7poonvnouAtYwBa6KDst9DM2R50oG4l1Pq9TEyg=";
  };

  # Custom install phase to avoid SPDX verification issues
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    
    # Install main binaries
    for bin in gnb srscu srscucp srscuup srsdu srsdu_low; do
      if [ -f "apps/$bin/$bin" ]; then
        install -Dm755 "apps/$bin/$bin" "$out/bin/$bin"
      elif [ -f "apps/*/$bin" ]; then
        install -Dm755 apps/*/$bin "$out/bin/$bin"
      fi
    done
    
    # Find and install all built executables
    find apps -type f -executable -name "gnb" -exec install -Dm755 {} "$out/bin/" \;
    find apps -type f -executable -name "srs*" -exec install -Dm755 {} "$out/bin/" \;
    
    runHook postInstall
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    fftwFloat
    mbedtls
    boost
    lksctp-tools
    yaml-cpp
    gtest
  ] ++ lib.optionals enableUHD [
    uhd
  ] ++ lib.optionals enableZeroMQ [
    zeromq
  ];

  cmakeFlags = [
    "-DENABLE_EXPORT=OFF"
    "-DAUTO_DETECT_ISA=OFF"
    "-DENABLE_SPDX=OFF"  # Disable SPDX generation (causes install issues)
    (lib.cmakeBool "ENABLE_UHD" enableUHD)
    (lib.cmakeBool "ENABLE_ZEROMQ" enableZeroMQ)
    (lib.cmakeBool "ENABLE_AVX" enableAvx)
    (lib.cmakeBool "ENABLE_AVX2" enableAvx2)
    (lib.cmakeBool "ENABLE_AVX512" enableAvx512)
  ];

  # Nix disables -march=native, so we need to explicitly enable CPU features
  # This ensures the cpu_features.h conditionals are properly defined
  # Also disable -Werror to fix GCC 15 sign-compare warnings
  NIX_CFLAGS_COMPILE = lib.concatStringsSep " " ([
    "-msse4.1"
    "-mpclmul"
    "-Wno-error"  # Fix GCC 15 warnings treated as errors
  ] ++ lib.optionals enableAvx [
    "-mavx"
  ] ++ lib.optionals enableAvx2 [
    "-mavx2"
    "-mfma"
  ] ++ lib.optionals enableAvx512 [
    "-mavx512f"
    "-mavx512vl"
    "-mavx512dq"
    "-mavx512cd"
    "-mavx512bw"
  ]);

  # Skip tests during build
  doCheck = false;

  meta = with lib; {
    description = "Open source O-RAN 5G CU/DU solution (gNB)";
    homepage = "https://www.srsran.com/";
    license = licenses.agpl3Plus;
    platforms = platforms.linux;
    maintainers = [];
  };
}

