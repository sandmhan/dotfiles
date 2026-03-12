
# Setup a Matrix server and an IRC bridge with NixOs

Something cool with software programming and open source:
there is always new projects to follow.
I understand it can be exhausting, especially if you are FOMO sensitive,
but what a treat !

Problem is: to communicate with their community, projects have the
choice of too many chat platforms: the current main one is [Discord](https://discord.gg)
followed by [Matrix](https://matrix.org), which offers the advantage of
self-hosting servers connected to a federation. The ancestor of all is
[IRC](https://en.wikipedia.org/wiki/IRC) with some communities still discussing here.

I discovered recently [tangled.sh](https://tangled.sh), a git collaboration platform,
built on the [AT Protocol](https://atproto.com/). As they wanted to discuss their development
and grow a community, they opened a room on the IRC [Libera.Chat](https://libera.chat/) server.

I also wanted to lurk in Nix and NixOs discussion channels and their community is using Matrix.

Thanks to the nixpkgs contributors, it is quite easy now to self host a Matrix server and
an irc bridge. I discovered the following stack: [conduit](https://conduit.rs/) and
[Heisenbridge](https://github.com/hifi/heisenbridge), thanks to this
[article](https://www.nat-418.xyz/posts/1ba7609d42e27999759eb4b9cd9810cb.html) from
[Nat-418](https://www.nat-418.xyz).

I modified the `configuration.nix` to add delegation to the matrix server and share
Heisenbridge app service credentials through [agenix](https://github.com/ryantm/agenix).

The main goal of this tutorial is to set up a matrix server to `matrix.example.com` and have
our user be authenticated to Matrix rooms with `@username:example.com`, then add an irc bridge
so we can use irc through our matrix server and client.


I wrote a [quick guide](/notes/install-nixos-on-an-ovh-vps-with-nixos-anywhere) on how to install
NixOs using `nixos-anywhere` on an Ovh vps.



You need to have a server running [NixOs](https://nixos.org).
Using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) makes it
easy to install on a vps. The server configuration should be in a NixOs flake.

Let's do it together:

## Setup the Matrix server

First Conduit will require a token to filter the registration of users;
the first user connect is the admin.
So we generate a quick token with this command:
```shell 
openssl rand --hex 16
```


We add the `matrix-conduit` service to the nix configuration:

```nix 

networking.firewall.allowedTCPPorts = [
    80
    443
    8448
];

services.matrix-conduit = {
    enable = true;
    settings.global = {
      address = "127.0.0.1";
      allow_registration = true;
      registration_token = "the token";
      database_backend = "rocksdb";
      port = 6167;
      server_name = "example.com";
    };
};

```


Port `8448` must be allowed, it is used by the Matrix server for federation.
We will change `allow_registration` to `false` and remove the `registration_token` line
after the first user (admin) is registered.

[Caddy](https://caddyserver.com/) is a HTTP server that manage for us  automatic tls
certificates and encryption. We will use it as a reverse proxy to the matrix server and
our current app behind `example.com` DNS domain.


**What is delegation ?**

By default, other matrix servers will expect to be able to reach ours via our server_name, on port 8448.
For example, if you set your server_name to example.com (so that your user names look like @user:example.com),
other servers will try to connect to ours at https://example.com:8448/.

Delegation is a Matrix feature allowing a matrix server admin to retain a server_name of example.com so that user IDs,
room aliases, etc continue to look like *:example.com, the federation traffic is routed to a different server and/or port
(e.g. matrix.example.com:443).



Delegation is done by setting up a [`./well-known URI`](https://en.wikipedia.org/wiki/Well-known_URI),
that gives the information for other federated matrix server connecting to `example.com`
that the real server is at `matrix.example.com`. An other URI is for the matrix client.

```nix 

services.caddy = {
    enable = true;
    configFile = pkgs.writeText "Caddyfile" ''
      matrix.example.com, matrix.example.com:8448 {
        reverse_proxy /_matrix/* 127.0.0.1:6167
      }

      example.com {
        handle /.well-known/matrix/server {
          respond `{"m.server": "matrix.example.com:443"}`
          header Content-Type application/json
        }

        handle /.well-known/matrix/client {
          respond `{"m.homeserver":{"base_url":"https://matrix.example.com"}}`
          header Content-Type application/json
          header Access-Control-Allow-Origin *
        }

        log_skip /.well-known*

        # the rest of your Caddy file configuration for the domain
     }
    '';
  };

```


We deploy the new configuration:

```shell 
nixos-rebuild switch 100  9426 100  9426   0  --flake .#ovh-vps --target-host "root@example.com"
```


We can then test that federation is working by entering
the matrix server domain in https://federationtester.matrix.org/

Not all Matrix clients support the user registration with a token, to quickly do it we
can use https://app.element.io and do it through the browser.
We can change then `allow_registration` to `false` and remove the `registration_token` line from the
`configuration.nix` and `rebuild-switch`.

# Add an IRC bridge


```sidenote-ascii-art
     ██████████████
    ██████████████████
    ██████████████████
    ██████████████████
    ██████████████████
██████████████████████████

  ██████████████████████
  █████████    █████████
    ███   0  6553     0   0:00:01  0:0██        █████

           ████
       ████████████
       ██        ██
       ██  ████  ██
         ████████

```
the [Heisenbridge](https://github.com/hifi/heisenbridge) logo



Matrix is cool, but IRC is old school cool.

We can have both thanks to another service: [Heisenbridge](https://github.com/hifi/heisenbridge).
That will connect on behalf of a matrix user to IRC servers and channels and create corresponding
Matrix room with mirrored users and messages. Logs are then stored for you like an IRC bouncer.

Heisenbridge requires a configuration file that will be also passed to the Matrix server
to safely do the API requests.

```shell 
nix-shell --packages heisenbridge \
    --command "heisenbridge --generate-compat --config heisenbridge-cfg.yml"

```


Once the configuration file generated, we need to register a new service for the matrix server
by writing in the admin channel a message. We compose a message to notif0:01 --:--:--  6553y the admin bot
about registering a new app service and provide its configuration in a markdown code block:

```text 
@conduit:example.com: register-appservice
```
// the content of heisenbridge-cfg.yml
```

```


We can then check that the service was registered by asking the admin bot to list them:

```text 
@conduit:example.com: list-appservices
```


Now we will safely store the configuration file in our folder with encryption using agenix.

We retrieve the public SSH key from the host, if we don't have it:

```shell 
ssh-keyscan matrix.example.com
```


and we add the ssh-rsa line to your flake's `secrets` folder in the file `secrets/secrets.nix`:

```nix 

let
  vps_ssh = "ssh-rsa ...";
in
{
  "heisenbridge-config.age".publicKeys = [ vps_ssh ];
}

```


We use agenix to encrypt the `heisenbridge-config` file according to the `secrets.nix` configuration:

```shell 
cd secrets/
agenix -e heisenbridge-config.age < heisenbridge-cfg.yml
```



Then we specify for agenix the decryption key in the `configurat100  9426 100  9426   0     0  6552     0   0:00:01  0:00:01 -ion.-:--:--     0
nix` and the file to decrypt for
the Heisenbridge service. We add the service with the `config` flag pointing to the decrypted secret file.

Configuration includes also our matrix server url and our matrix user that will use
the bridge to join IRC servers.

```nix 
age.identityPaths = [ "/etc/ssh/ssh_host_rsa_key" ];

age.secrets."heisenbridge-config" = {
    file = ./secrets/heisenbridge-config.age;
    owner = "heisenbridge";
    group = "heisenbridge";
};

services.heisenbridge = {
    enable = true;
    extraArgs = ["--config" config.age.secrets.heisenbridge-config.path];
    debug = false;
    homeserver = "https://matrix.example.com";
    owner = "@ourusername:example.com";
};

```


We deploy the new configuration:

```shell 
nixos-rebuild switch --flake .#ovh-vps --target-host "root@example.com"
```


For an introduction to Heisenbridge and learn how to connect to an IRC server
and join a room, we can then follow the instruction used in this
[brief demonstration](https://www.youtube.com/watch?v=nQk1Bp4tk4I) from the creator Hifi.

------------------------------------------------
Copyright: 
$ pwd :    ~/edouard.paris/notes/2025-04-18_matrix-and-irc-on-nixos
------------------------------------------------

