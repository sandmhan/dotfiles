# rg Troubleshooting

## Exit Codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | Error |

## Common Issues

### Installation Failed

```bash
apt-get install -y rg
which rg
```

### File Not Found

```bash
ls -la file
rg /full/path/to/file
```

## Resources

- Manual: man rg
