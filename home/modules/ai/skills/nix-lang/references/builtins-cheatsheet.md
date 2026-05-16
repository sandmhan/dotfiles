# Nix Builtins Cheatsheet

## String Operations

```
builtins.substring : int -> int -> string -> string
```
`builtins.substring 0 3 "hello"` => `"hel"`

```
builtins.replaceStrings : [string] -> [string] -> string -> string
```
`builtins.replaceStrings ["o"] ["0"] "foo"` => `"f00"`

```
builtins.stringLength : string -> int
```
`builtins.stringLength "nix"` => `3`

```
builtins.match : string -> string -> [string] | null
```
`builtins.match "([a-z]+)-([0-9]+)" "pkg-42"` => `["pkg" "42"]`

```
builtins.split : string -> string -> [string | [string]]
```
`builtins.split "," "a,b,c"` => `["a" [","] "b" [","] "c"]`

```
builtins.concatStringsSep : string -> [string] -> string
```
`builtins.concatStringsSep "/" ["a" "b" "c"]` => `"a/b/c"`

```
builtins.toString : a -> string
```
`builtins.toString 42` => `"42"`

```
builtins.toJSON : a -> string
```
`builtins.toJSON { x = 1; }` => `"{\"x\":1}"`

```
builtins.fromJSON : string -> a
```
`builtins.fromJSON "{\"x\":1}"` => `{ x = 1; }`

## List Operations

```
builtins.map : (a -> b) -> [a] -> [b]
```
`builtins.map (x: x * 2) [1 2 3]` => `[2 4 6]`

```
builtins.filter : (a -> bool) -> [a] -> [a]
```
`builtins.filter (x: x > 2) [1 2 3 4]` => `[3 4]`

```
builtins.foldl' : (b -> a -> b) -> b -> [a] -> b
```
`builtins.foldl' (acc: x: acc + x) 0 [1 2 3]` => `6`

```
builtins.head : [a] -> a
```
`builtins.head [1 2 3]` => `1`

```
builtins.tail : [a] -> [a]
```
`builtins.tail [1 2 3]` => `[2 3]`

```
builtins.length : [a] -> int
```
`builtins.length [1 2 3]` => `3`

```
builtins.elem : a -> [a] -> bool
```
`builtins.elem 2 [1 2 3]` => `true`

```
builtins.concatLists : [[a]] -> [a]
```
`builtins.concatLists [[1 2] [3 4]]` => `[1 2 3 4]`

```
builtins.sort : (a -> a -> bool) -> [a] -> [a]
```
`builtins.sort builtins.lessThan [3 1 2]` => `[1 2 3]`

```
builtins.genList : (int -> a) -> int -> [a]
```
`builtins.genList (i: i * 10) 3` => `[0 10 20]`

```
builtins.groupBy : (a -> string) -> [a] -> attrset
```
`builtins.groupBy (x: if x > 2 then "big" else "small") [1 2 3 4]` => `{ big = [3 4]; small = [1 2]; }`

## Attrset Operations

```
builtins.attrNames : attrset -> [string]
```
`builtins.attrNames { b = 2; a = 1; }` => `["a" "b"]`

```
builtins.attrValues : attrset -> [a]
```
`builtins.attrValues { a = 1; b = 2; }` => `[1 2]`

```
builtins.hasAttr : string -> attrset -> bool
```
`builtins.hasAttr "x" { x = 1; }` => `true`

```
builtins.getAttr : string -> attrset -> a
```
`builtins.getAttr "x" { x = 1; }` => `1`

```
builtins.removeAttrs : attrset -> [string] -> attrset
```
`builtins.removeAttrs { a = 1; b = 2; } ["b"]` => `{ a = 1; }`

```
builtins.intersectAttrs : attrset -> attrset -> attrset
```
`builtins.intersectAttrs { a = 1; b = 2; } { b = 10; c = 3; }` => `{ b = 10; }`

```
builtins.mapAttrs : (string -> a -> b) -> attrset -> attrset
```
`builtins.mapAttrs (name: val: val * 2) { a = 1; b = 2; }` => `{ a = 2; b = 4; }`

```
builtins.catAttrs : string -> [attrset] -> [a]
```
`builtins.catAttrs "x" [{ x = 1; } { y = 2; } { x = 3; }]` => `[1 3]`

```
builtins.listToAttrs : [{ name : string; value : a }] -> attrset
```
`builtins.listToAttrs [{ name = "x"; value = 1; }]` => `{ x = 1; }`

## Path Operations

```
builtins.readFile : path -> string
```
`builtins.readFile ./version.txt` => contents of the file as a string

```
builtins.readDir : path -> attrset
```
`builtins.readDir ./src` => `{ "main.c" = "regular"; "lib" = "directory"; }`

```
builtins.path : { path, name?, filter?, recursive?, sha256? } -> path
```
`builtins.path { path = ./src; name = "my-source"; }` => filtered store path

```
builtins.pathExists : path -> bool
```
`builtins.pathExists ./flake.nix` => `true` or `false`

```
builtins.toPath : string -> path
```
`builtins.toPath "/tmp/foo"` => `/tmp/foo` (deprecated, prefer path literals)

```
builtins.dirOf : path|string -> path|string
```
`builtins.dirOf /tmp/foo/bar.txt` => `/tmp/foo`

```
builtins.baseNameOf : path|string -> string
```
`builtins.baseNameOf /tmp/foo/bar.txt` => `"bar.txt"`

## Type Checks

```
builtins.isString : a -> bool
builtins.isInt    : a -> bool
builtins.isBool   : a -> bool
builtins.isList   : a -> bool
builtins.isAttrs  : a -> bool
builtins.isFunction : a -> bool
builtins.isPath   : a -> bool
builtins.isNull   : a -> bool
builtins.isFloat  : a -> bool
```
`builtins.isAttrs { x = 1; }` => `true`

```
builtins.typeOf : a -> string
```
`builtins.typeOf 42` => `"int"`

## Derivation & Fetchers

```
builtins.derivation : attrset -> derivation
```
`builtins.derivation { name = "hello"; builder = "/bin/sh"; args = ["-c" "echo hi > $out"]; system = builtins.currentSystem; }` — low-level; prefer `mkDerivation`.

```
builtins.fetchurl : string|attrset -> path
```
`builtins.fetchurl "https://example.com/file.tar.gz"` => store path

```
builtins.fetchTarball : string|attrset -> path
```
`builtins.fetchTarball { url = "https://example.com/src.tar.gz"; sha256 = "..."; }` => unpacked store path

```
builtins.fetchGit : attrset -> attrset
```
`builtins.fetchGit { url = "https://github.com/owner/repo"; rev = "abc123"; }` => `{ outPath, rev, shortRev, ... }`

## Import

```
builtins.import : path -> a
```
`builtins.import ./default.nix` => evaluates and returns the Nix expression in the file

```
builtins.scopedImport : attrset -> path -> a
```
`builtins.scopedImport { x = 1; } ./file.nix` => imports with `x` in scope (rarely used)

## Evaluation Control

```
builtins.tryEval : a -> { success : bool; value : a }
```
`builtins.tryEval (1 / 0)` => `{ success = false; value = false; }`

```
builtins.throw : string -> error
```
`builtins.throw "something went wrong"` => aborts with message (catchable by `tryEval`)

```
builtins.abort : string -> error
```
`builtins.abort "fatal"` => aborts evaluation (NOT catchable by `tryEval`)

```
builtins.trace : a -> b -> b
```
`builtins.trace "debug: ${toString x}" x` => prints message to stderr, returns `x`

```
builtins.deepSeq : a -> b -> b
```
`builtins.deepSeq expr expr` => forces full evaluation of `expr` (catches hidden errors)

```
builtins.seq : a -> b -> b
```
`builtins.seq expr expr` => forces shallow evaluation of `expr`

## Miscellaneous

```
builtins.currentSystem : string
```
`builtins.currentSystem` => `"x86_64-linux"` or `"aarch64-darwin"` etc.

```
builtins.nixVersion : string
```
`builtins.nixVersion` => `"2.18.1"` (version of the evaluator)

```
builtins.storeDir : string
```
`builtins.storeDir` => `"/nix/store"`

```
builtins.getEnv : string -> string
```
`builtins.getEnv "HOME"` => `""` in pure evaluation mode; returns the value in impure mode
