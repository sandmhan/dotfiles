# ssh Client Cheatsheet

## Strict defaults

- `StrictHostKeyChecking=yes`
- `BatchMode=yes`
- `UserKnownHostsFile=~/.ssh/known_hosts`

## Common checks

1. Add host key

```bash
ssh-keyscan -p 22 github.com >> ~/.ssh/known_hosts
```

1. Verify host key presence

```bash
ssh-keygen -F github.com -f ~/.ssh/known_hosts
```

1. Probe auth path

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=yes git@github.com
```
