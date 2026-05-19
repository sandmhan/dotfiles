# jq Troubleshooting

## Exit Codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | Error |

## Common Issues

### Installation Failed

```bash
apt-get install -y jq
which jq
```

### File Not Found

```bash
ls -la file
jq /full/path/to/file
```

## Resources

- Manual: man jq
