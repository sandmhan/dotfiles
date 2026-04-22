# Nixpkgs Lib Functions Reference

## lib.attrsets

```
lib.filterAttrs : (string -> a -> bool) -> attrset -> attrset
```
`lib.filterAttrs (n: v: v != null) { a = 1; b = null; }` => `{ a = 1; }`

```
lib.mapAttrs : (string -> a -> b) -> attrset -> attrset
```
`lib.mapAttrs (name: val: "${name}=${val}") { x = "1"; y = "2"; }` => `{ x = "x=1"; y = "y=2"; }`

```
lib.mapAttrs' : (string -> a -> { name : string; value : b }) -> attrset -> attrset
```
`lib.mapAttrs' (n: v: { name = "prefix-${n}"; value = v; }) { a = 1; }` => `{ prefix-a = 1; }`

```
lib.recursiveUpdate : attrset -> attrset -> attrset
```
`lib.recursiveUpdate { a.b = 1; a.c = 2; } { a.b = 10; }` => `{ a = { b = 10; c = 2; }; }`

```
lib.nameValuePair : string -> a -> { name : string; value : a }
```
`lib.nameValuePair "foo" 42` => `{ name = "foo"; value = 42; }`

```
lib.genAttrs : [string] -> (string -> a) -> attrset
```
`lib.genAttrs ["x" "y"] (name: "val-${name}")` => `{ x = "val-x"; y = "val-y"; }`

```
lib.zipAttrsWithNames : [string] -> (string -> [a] -> b) -> [attrset] -> attrset
```
`lib.zipAttrsWithNames ["a"] (n: vs: builtins.head vs) [{ a = 1; } { a = 2; }]` => `{ a = 1; }`

## lib.lists

```
lib.flatten : [a | [a]] -> [a]
```
`lib.flatten [[1 2] [3 [4]]]` => `[1 2 3 4]`

```
lib.unique : [a] -> [a]
```
`lib.unique [1 2 1 3 2]` => `[1 2 3]`

```
lib.remove : a -> [a] -> [a]
```
`lib.remove 2 [1 2 3 2]` => `[1 3]`

```
lib.subtractLists : [a] -> [a] -> [a]
```
`lib.subtractLists [2 4] [1 2 3 4 5]` => `[1 3 5]`

```
lib.partition : (a -> bool) -> [a] -> { right : [a]; wrong : [a] }
```
`lib.partition (x: x > 2) [1 2 3 4]` => `{ right = [3 4]; wrong = [1 2]; }`

```
lib.findFirst : (a -> bool) -> a -> [a] -> a
```
`lib.findFirst (x: x > 2) null [1 2 3 4]` => `3`

```
lib.count : (a -> bool) -> [a] -> int
```
`lib.count (x: x > 2) [1 2 3 4]` => `2`

```
lib.imap0 : (int -> a -> b) -> [a] -> [b]
```
`lib.imap0 (i: v: "${toString i}:${v}") ["a" "b"]` => `["0:a" "1:b"]`

```
lib.imap1 : (int -> a -> b) -> [a] -> [b]
```
`lib.imap1 (i: v: "${toString i}:${v}") ["a" "b"]` => `["1:a" "2:b"]`

```
lib.zipListsWith : (a -> b -> c) -> [a] -> [b] -> [c]
```
`lib.zipListsWith (a: b: a + b) [1 2] [10 20]` => `[11 22]`

## lib.strings

```
lib.concatStrings : [string] -> string
```
`lib.concatStrings ["a" "b" "c"]` => `"abc"`

```
lib.concatMapStrings : (a -> string) -> [a] -> string
```
`lib.concatMapStrings (x: "${x}\n") ["a" "b"]` => `"a\nb\n"`

```
lib.concatStringsSep : string -> [string] -> string
```
`lib.concatStringsSep ", " ["a" "b" "c"]` => `"a, b, c"`

```
lib.hasPrefix : string -> string -> bool
```
`lib.hasPrefix "foo" "foobar"` => `true`

```
lib.hasSuffix : string -> string -> bool
```
`lib.hasSuffix ".nix" "default.nix"` => `true`

```
lib.removePrefix : string -> string -> string
```
`lib.removePrefix "foo" "foobar"` => `"bar"`

```
lib.removeSuffix : string -> string -> string
```
`lib.removeSuffix ".nix" "default.nix"` => `"default"`

```
lib.toLower : string -> string
```
`lib.toLower "Hello"` => `"hello"`

```
lib.toUpper : string -> string
```
`lib.toUpper "hello"` => `"HELLO"`

```
lib.escapeShellArg : string -> string
```
`lib.escapeShellArg "hello world"` => `"'hello world'"`

```
lib.optionalString : bool -> string -> string
```
`lib.optionalString true "yes"` => `"yes"`

## lib.trivial

```
lib.pipe : a -> [(a -> b)] -> b
```
`lib.pipe 2 [(x: x + 3) (x: x * 2)]` => `10`

```
lib.flip : (a -> b -> c) -> b -> a -> c
```
`lib.flip lib.hasPrefix ".nix" "default.nix"` => applies with args swapped

```
lib.const : a -> b -> a
```
`lib.const 42 "ignored"` => `42`

```
lib.id : a -> a
```
`lib.id 42` => `42`

```
lib.mapNullable : (a -> b) -> a | null -> b | null
```
`lib.mapNullable (x: x + 1) null` => `null`

```
lib.throwIf : bool -> string -> a -> a
```
`lib.throwIf (x == "") "x must not be empty" x` => throws if condition is true

```
lib.warnIf : bool -> string -> a -> a
```
`lib.warnIf (x == "") "x is empty" x` => prints warning if condition is true, returns value

## lib.debug

```
lib.traceVal : a -> a
```
`lib.traceVal myExpr` => prints `myExpr` to stderr, returns it

```
lib.traceValFn : (a -> b) -> a -> a
```
`lib.traceValFn (x: "value is ${toString x}") 42` => prints custom message, returns `42`

```
lib.traceSeq : a -> b -> b
```
`lib.traceSeq (builtins.deepSeq expr expr) result` => forces and traces `expr`, returns `result`

## lib.types (Module Option Types)

```
types.str              # non-empty string
types.int              # integer
types.bool             # boolean (default merging: AND)
types.path             # path to file/directory
types.listOf types.str # list of strings
types.attrsOf types.int # attrset of ints
types.enum ["a" "b"]   # one of the listed values
types.nullOr types.str  # string or null
types.oneOf [types.str types.int] # union type
types.submodule { options = { ... }; } # nested module
types.port             # integer 0-65535
types.package          # a derivation
types.lines            # multi-line string (merged with newlines)
types.commas           # string (merged with commas)
types.anything         # any value (useful for freeform config)
```

Usage in module options:
```nix
options.myService.port = lib.mkOption {
  type = lib.types.port;
  default = 8080;
  description = "Port to listen on";
};
```

## lib.generators

```
lib.generators.toINI : { mkKeyValue? } -> attrset -> string
```
`lib.generators.toINI {} { section = { key = "value"; }; }` => `"[section]\nkey=value\n"`

```
lib.generators.toKeyValue : { mkKeyValue?, listsAsDuplicateKeys? } -> attrset -> string
```
`lib.generators.toKeyValue {} { a = "1"; b = "2"; }` => `"a=1\nb=2\n"`

```
lib.generators.toYAML : {} -> a -> string
```
`lib.generators.toYAML {} { x = [1 2]; }` => YAML representation

```
lib.generators.toPretty : { multiline?, indent? } -> a -> string
```
`lib.generators.toPretty {} { a = [1 2]; }` => pretty-printed Nix value
