## What does this change?

<!-- One or two sentences. Example: "Adds multi-select course moves to the floor service and the Tables tab." -->

## Scenario and area

- **Scenario:** <!-- 1 Take an order / 2 Fix it on the floor / 3 Close the shift / Shared -->
- **Area:** <!-- adt / backend / frontend / database / docs -->
- **Related issue:** <!-- #number, if any -->

## Type of change

- [ ] New feature
- [ ] Bug fix
- [ ] Refactor (no behavior change)
- [ ] Database schema or seed data
- [ ] Docs only

## How was it tested?

<!-- Steps a reviewer can repeat. Example: "Ran both SQL scripts, started backend and frontend, moved two items on Table 2 to course 1, pressed Undo." -->

**Tested on:** [ ] Mac  [ ] Windows

## Screenshots

<!-- For UI changes, add before/after screenshots. Delete this section otherwise. -->

## Checklist

**Builds and runs**
- [ ] Backend builds and starts against the seeded database
- [ ] Frontend runs with `npm run dev` and the three tabs open
- [ ] New or changed ADT methods have tests, and all tests pass

**Project rules**
- [ ] No `java.util` collections in `adt/` or in the scenario logic
- [ ] Sorting and totals run in Java on our ADTs, not in SQL (`ORDER BY` / `GROUP BY`)
- [ ] All code in this pull request was written by our team (course AI rules)

**Shared files**
- [ ] If I changed a shared file (`pom.xml`, `package.json`, `App.jsx`, `BizkitApplication.java`, `common/`, SQL scripts), I kept the change small and posted in the group chat
- [ ] If I added or changed an endpoint, I updated `docs/api.md` in this pull request
- [ ] If I added a table, I also added it to the `TABLES` list in `build_dist.sh` and to `pre-deployment/drop_all_objects.sql` (children first); new seed files are in the `SEEDS` list
- [ ] If I changed `database/src` or seeds, I ran `build_dist.sh` locally, the schema script ran cleanly twice in a row, the seed script loaded, and the `tests/` queries passed
- [ ] I did **not** commit changes to `database/dist/` (it is rebuilt on `main` after merging)

**Safety**
- [ ] No `.env` files, passwords or personal data are committed
