# node24_repo

## Reassemble & Load Docker Images

### postgres:15

**Linux / WSL / macOS:**
```bash
cat postgres_15.tar.gz.part_* > postgres_15.tar.gz
docker load -i postgres_15.tar.gz
```

**Windows (Command Prompt):**
```cmd
copy /b postgres_15.tar.gz.part_aa + postgres_15.tar.gz.part_ab + postgres_15.tar.gz.part_ac postgres_15.tar.gz
docker load -i postgres_15.tar.gz
```