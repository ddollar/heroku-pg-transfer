# heroku-pg-transfer

## Installation

    $ heroku plugins:install https://github.com/ddollar/heroku-pg-transfer

## Usage

    $ heroku help pg:transfer
	Usage: heroku pg:transfer

	 transfer data between databases

	 -f, --from           DATABASE  # source database, defaults to DATABASE_URL on the app
     -t, --to             DATABASE  # target database, defaults to local $DATABASE_URL
     -b, --tables         DATABASE  # tables to copy, defaults to all
     -B, --exclude_tables DATABASE  # tables to exclude, defaults to none
#
    $ env DATABASE_URL=postgres://localhost/myapp-development heroku pg:transfer
    Source database: DATABASE on myapp.herokuapp.com
    Target database: myapp-development on localhost:5432
    pg_dump: reading schemas
    pg_dump: reading user-defined tables
    ...
#
    $ heroku pg:transfer --from charcoal --to postgres://foo
    Source database: HEROKU_POSTGRESQL_CHARCOAL on myapp.herokuapp.com
    Target database: foo on localhost:5432
    pg_dump: reading schemas
    pg_dump: reading user-defined tables
    ...
#
    $ source .env && heroku pg:transfer --from $DATABASE_URL --to charcoal
    Source database: myapp-development on localhost:5432
    Target database: HEROKU_POSTGRESQL_CHARCOAL on myapp.herokuapp.com
    pg_dump: reading schemas
    pg_dump: reading user-defined tables
    ...
#
    # detects non-postgres url
    $ heroku pg:transfer --to mysql://foo
    !    Only PostgreSQL databases can be transferred with this command.
    !    For information on transferring other database types, see:
    !    https://devcenter.heroku.com/articles/import-data-heroku-postgres
#
    # if they dont have a local $DATABASE_URL
    $ heroku pg:transfer
    !    No local DATABASE_URL detected and --to not specified.
    !    For information on using config vars locally, see:
    !    https://devcenter.heroku.com/articles/config-vars#local_setup
