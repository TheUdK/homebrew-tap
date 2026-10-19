# TheUdK Homebrew Tap

Personal Homebrew tap.

## How do I install these formulae?

`brew install theudk/tap/<formula>`

Or `brew tap theudk/tap` and then `brew install <formula>`.

Or, in a `brew bundle` `Brewfile`:

```ruby
tap "theudk/tap"
brew "<formula>"
```

## Formulae

| Formula | Description | Notes |
|---|---|---|
| `openssh-gssapi` | OpenSSH with Debian's GSS-API authentication and key exchange patch (`GSSAPIKeyExchange`, `GSSAPIClientIdentity`, …) | Conflicts with core `openssh` (`brew unlink openssh` first). Kept in lockstep with core `openssh` by `bin/sync-openssh-gssapi` and the daily `sync-openssh-gssapi` workflow, which only bumps once Debian's `src:openssh-gssapi` has a matching release tag. |

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
