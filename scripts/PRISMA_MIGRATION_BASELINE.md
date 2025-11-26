Prisma: handling P3005 (schema not empty) during automated deploys

What is P3005?
--------------
Prisma error `P3005` occurs when the migration engine tries to apply migrations to a database that already contains schema objects (tables) but does not match Prisma's migration history. This frequently happens when:
- The database was created or modified outside Prisma migrations (e.g., manual DDL, dev db push). 
- Migrations were applied by a different mechanism or a different migration table.

Options and recommendations
---------------------------
- Safe approach for production: Create a baseline migration that reflects the current DB schema. The team must generate a migration that captures the current schema and mark it as applied in the `prisma_migrations` table. See https://www.prisma.io/docs/guides/database/developing-with-prisma-migrate#baseline-an-existing-database
- For CI/automated deploys: Usually running `npx prisma migrate deploy` is desired. If it fails with P3005, do NOT force `db push` in production. Instead:
  1. Inspect the DB and confirm it was sandboxed or modified manually.
  2. If the migration history is missing, create a baseline migration: `npx prisma migrate resolve --applied "<migration-id>"`, or if appropriate regenerate a migration that matches the current schema.
  3. After baseline is set or migration is applied manually, re-run `npx prisma migrate deploy`.

CI behavior in this repo
-----------------------
- The deploy workflow captures Prisma migration output and prints a helpful message if P3005 is detected. The job does not abort the workflow immediately because the team currently accepts that migrations might be intentionally handled by an operator.

If you want to automate a safe fallback in CI (dangerous):
-----------------------------------------------------
- Option: Add an environment variable `PRISMA_FALSE_POSITIVE_P3005_ALLOW=<true|false>` and, if true, run `npx prisma db push --accept-data-loss` to synchronize the schema. This is risky—`db push --accept-data-loss` can remove columns and data.

If you'd like, I can implement an optional 'safe baseline' automation as a PR, but this requires careful testing and policy decisions.

