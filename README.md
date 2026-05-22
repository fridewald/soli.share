# soli

Share costs in a group in a pay as you think approach.


## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Database integration

Copy `env_template` to `.env` and update the DATABASE_URL.

Use <https://github.com/amacneil/dbmate> for database migration.

```
dbmate up
```

Use <https://hexdocs.pm/parrot/parrot.html> to generate gleam bindings.

```
gleam run -m parrot -- --sqlite <db_file_name>.sqlite3

```
