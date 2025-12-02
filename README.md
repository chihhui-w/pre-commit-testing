
## Steps

### Install pre-commit
```bash
brew install pre-commit
```

### Setup config

See `.pre-commit-config.yaml`


### Install hooks
```bash
pre-commit install
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-push
```

### Make scripts executable
```bash
chmod +x scripts/*
```
