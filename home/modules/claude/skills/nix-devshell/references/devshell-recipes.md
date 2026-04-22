# Dev Shell Recipes

Drop-in `mkShell` blocks for flake `devShells` output. Each assumes the standard flake pattern:

```nix
# In perSystem or with system-specific pkgs:
devShells.default = pkgs.mkShell { /* ... */ };
```

---

## Python (with venv)

```nix
pkgs.mkShell {
  packages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
  ];

  buildInputs = with pkgs; [
    openssl
    zlib
    libffi
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  env.LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ openssl zlib libffi ]);

  shellHook = ''
    if [ ! -d .venv ]; then
      python -m venv .venv
    fi
    source .venv/bin/activate
  '';
}
```

---

## Rust

```nix
pkgs.mkShell {
  packages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    libiconv
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  env = {
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  shellHook = ''
    echo "Rust $(rustc --version)"
  '';
}
```

> **macOS gotcha**: Rust crates linking to native libraries (openssl, curl) need `libiconv` and Security framework on Darwin.

---

## Node.js

```nix
pkgs.mkShell {
  packages = with pkgs; [
    nodejs
    pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];

  shellHook = ''
    echo "Node $(node --version)"
  '';
}
```

> For packaging Node projects in Nix, see `node2nix`, `dream2nix`, or `buildNpmPackage`.

---

## Go

```nix
pkgs.mkShell {
  packages = with pkgs; [
    go
    gopls
    delve
    golangci-lint
  ];

  env.GOPATH = "$PWD/.go";
  env.CGO_ENABLED = "0";

  shellHook = ''
    export PATH="$GOPATH/bin:$PATH"
    echo "Go $(go version)"
  '';
}
```

> **CGO note**: Set `CGO_ENABLED = "1"` and add `gcc`/`pkg-config` to `packages` if you need cgo. On macOS, ensure the SDK frameworks are available.

---

## C/C++

```nix
pkgs.mkShell {
  packages = with pkgs; [
    gcc
    cmake
    gnumake
    pkg-config
  ] ++ lib.optionals stdenv.isLinux [
    gdb
    valgrind
  ] ++ lib.optionals stdenv.isDarwin [
    lldb
  ];

  buildInputs = with pkgs; [
    openssl
    zlib
  ];

  shellHook = ''
    echo "GCC $(gcc --version | head -1)"
  '';
}
```

> For clang instead of gcc, replace `gcc` with `clang` and add `llvmPackages.libcxx` to `buildInputs` if needed.

---

## Haskell

```nix
pkgs.mkShell {
  packages = with pkgs; [
    ghc
    cabal-install
    haskell-language-server
    haskellPackages.fourmolu
  ];

  buildInputs = with pkgs; [
    zlib
    pkg-config
  ] ++ lib.optionals stdenv.isDarwin [
    libiconv
  ];

  shellHook = ''
    echo "GHC $(ghc --version)"
  '';
}
```

---

## Java / Kotlin

```nix
pkgs.mkShell {
  packages = with pkgs; [
    jdk
    gradle
    kotlin
  ];

  env.JAVA_HOME = "${pkgs.jdk}";

  shellHook = ''
    echo "Java $(java --version 2>&1 | head -1)"
  '';
}
```

> Swap `gradle` for `maven` as needed. Pin JDK version with `jdk17`, `jdk21`, etc.

---

## Shell / Scripts

```nix
pkgs.mkShellNoCC {
  packages = with pkgs; [
    shellcheck
    shfmt
    bash
    jq
    yq-go
  ];

  shellHook = ''
    echo "ShellCheck $(shellcheck --version | grep version:)"
  '';
}
```

> Uses `mkShellNoCC` — no C compiler needed for scripting tools.

---

## Nix Itself

```nix
pkgs.mkShellNoCC {
  packages = with pkgs; [
    nil
    nixfmt-rfc-style
    deadnix
    statix
    nix-diff
  ];

  shellHook = ''
    echo "Nix tooling shell ready"
  '';
}
```

---

## Multi-Language (combining shells)

Use `inputsFrom` to compose shells without duplicating package lists:

```nix
let
  pythonShell = pkgs.mkShell {
    packages = with pkgs; [ python3 python3Packages.pip ];
  };
  nodeShell = pkgs.mkShell {
    packages = with pkgs; [ nodejs pnpm ];
  };
in
pkgs.mkShell {
  inputsFrom = [ pythonShell nodeShell ];

  packages = with pkgs; [
    just
    direnv
  ];

  shellHook = ''
    echo "Multi-language dev shell ready"
  '';
}
```

> `inputsFrom` merges all `buildInputs`, `nativeBuildInputs`, and propagated inputs from the listed derivations. Add project-wide tools in the outer shell's `packages`.
