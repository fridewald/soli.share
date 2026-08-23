# soli

Split costs in a group in a pay as you think approach.

An user can and their spending in the web ui, they become the creator of the spending.
Via a link each participant than pledges an amount they seem fit.
The creator has a separate link to terminate the spending session.


## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam dev   # Run the dev-server
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
