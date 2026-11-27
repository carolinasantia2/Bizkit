# Bizkit

A server-focused restaurant point-of-sale (POS) app that makes three everyday workflows faster than they are in tools like Toast: changing the course of several items at once, fixing an order rung in at the wrong table, and closing a shift while tabs are still open.

Built for **INFO 6205 Program Structure and Algorithms** (Fall 2026, Northeastern University) as a demonstration of custom data structures and algorithms behind a real-world interface.

---

## Table of contents

- [The problem](#the-problem)
- [Features](#features)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Data structures and algorithms](#data-structures-and-algorithms)
- [Repository structure](#repository-structure)
- [Getting started](#getting-started)
- [Demo walkthrough](#demo-walkthrough)
- [Team](#team)
- [Database workflow](#database-workflow)
- [Contributing](#contributing)
- [Documentation](#documentation)

---

## The problem

Bizkit is based on feedback from restaurant staff who use Toast every shift:

| # | Reported problem | What Toast offers today | What Bizkit does |
| --- | --- | --- | --- |
| 1 | Can't change the course of several selected items at once | Possible only with a per-device setting turned on | Multi-select course changes are the default |
| 2 | Moving an order to the right table leaves a second check | Workaround: choose merge in the move flow, or combine checks on another screen | Moving onto a table with one check merges automatically |
| 3 | A shift can't be closed while any tab is open | Workaround: close, void or transfer every open check first | Close the shift and carry open tabs over in one prompt |

## Features

**Scenario 1 – Take an order**
- Browse the menu by category (menu → group → item)
- Add items with add-ons; the price updates live
- Assign each item to a course
- Undo any change from the top bar

**Scenario 2 – Fix it on the floor**
- Select several items and move them to another course in one action
- Move items to another table with automatic merging
- Split a guest's items into a new check
- Warning when paying a check while the table still has other open checks
- Undo for moves, merges and splits

**Scenario 3 – Close the shift**
- See paid checks and open tabs side by side
- Carry open tabs over to the next shift
- Shift report built from paid checks only, sortable by quantity or revenue
- Sales by category and a timing comparison of two sorting algorithms

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | React, Vite |
| Backend | Java, Spring Boot (Spring Web), plain JDBC |
| Database | Microsoft SQL Server (Docker on Mac, native on Windows) |
| Build | Maven (backend), npm (frontend) |
| Tools | Eclipse (backend), VS Code (frontend), VS Code SQL Server extension or DBeaver (Mac), SSMS (Windows) |

## Architecture

```
React (browser)  →  Java REST API  →  Services using our custom ADTs  →  SQL database
   UI only          controllers        all scenario logic                 persistence only
```

- **Frontend** shows the three tabs and sends each user action to the API. It holds no business logic.
- **Backend** loads the database into our custom data structures at startup. Every scenario runs on those structures, and each change is then saved to the database.
- **Database** stores data between runs. It is created and filled by the two scripts in `database/`.

> **Core rule:** the backend never hands the real work to SQL or to Java's built-in collections. Reports are sorted with our own sorting algorithms (not `ORDER BY`), category totals come from recursion over our menu tree (not `GROUP BY`), and the core code uses no `java.util` collections.

## Data structures and algorithms

Every data structure is designed as an interface (the ADT) and implemented by the team.

| Course topic | Where it is used |
| --- | --- |
| Trees | `MenuTree` – a linked general tree of categories, items and add-ons |
| Recursion | Finding items, pricing an item with its add-ons, category sales totals |
| Lists | Checks on a table, courses on a check, items in a course |
| Iterators | Custom iterator over the List ADT, used for totals and JSON conversion |
| Stacks | `LinkedStack` behind Undo |
| Sorting | Two sorting algorithms for the shift report |
| Efficiency of algorithms | Timing comparison of the two sorts |

## Repository structure

```
bizkit/
├── README.md
├── RUN_INSTRUCTIONS.txt        step-by-step run guide for grading
├── .gitignore
├── .github/
│   ├── CODEOWNERS              auto-assigns reviewers by folder
│   └── pull_request_template.md
├── docs/
│   ├── api.md                  REST endpoint contract
│   ├── design-doc.pdf
│   ├── erd.png
│   └── wireframes/
├── database/                   see "Database workflow" below
│   ├── src/
│   │   ├── tables/             one CREATE TABLE file per table, by domain
│   │   │   ├── 01_foundation/
│   │   │   ├── 02_menu/
│   │   │   ├── 03_checks_orders/
│   │   │   ├── 04_floor_operations/
│   │   │   ├── 05_payments/
│   │   │   └── 06_shift_close/
│   │   ├── programmability/    triggers/, views/ (only if needed)
│   │   └── indexes/            IX_ files (only if needed)
│   ├── scripts/
│   │   ├── build_dist.sh       assembles dist/ from src/ and scripts/
│   │   ├── pre-deployment/     create database, drop all objects (children first)
│   │   └── post-deployment/    seed INSERTs, one file per domain
│   ├── tests/                  read-only checks to run after building
│   └── dist/                   THE GRADED FILES. Generated; don't edit.
│       ├── 01_create_schema.sql
│       └── 02_insert_seed_data.sql
├── backend/                    Maven project (import into Eclipse)
│   ├── .env.example
│   ├── pom.xml
│   └── src/
│       ├── main/java/com/bizkit/
│       │   ├── BizkitApplication.java
│       │   ├── adt/            tree/, list/, stack/
│       │   ├── common/         shared model classes, DB config, CORS, errors
│       │   ├── menu/           menu browsing and pricing
│       │   ├── order/          adding items to checks
│       │   ├── floor/          moves, merges, splits, payments
│       │   ├── shift/          shift close and report
│       │   ├── undo/           undo manager and actions
│       │   └── sorting/        sorting algorithms and timer
│       └── test/java/com/bizkit/
└── frontend/                   React + Vite
    ├── .env.example
    ├── package.json
    └── src/
        ├── App.jsx             three-tab shell
        ├── api/                shared fetch wrapper
        ├── components/         TopBar, Dialog, Snackbar, CheckPanel
        ├── styles/             design tokens from the wireframes
        └── features/           order/, floor/, shift/
```

Each backend feature folder follows the same pattern: a **controller** (HTTP requests), a **service** (scenario logic on the ADTs), a **repository** (SQL for that feature) and a **dto/** folder (JSON shapes sent to the frontend).

## Getting started

### Prerequisites

- Git
- JDK (current LTS)
- Node.js (LTS)
- Microsoft SQL Server and a SQL client (see below)
- Eclipse IDE for Java Developers (backend)
- VS Code (optional, frontend)

**Mac** – with [Homebrew](https://brew.sh):

```bash
brew install git node
brew install --cask temurin
```

**Windows** – download and run the installers from [git-scm.com](https://git-scm.com), [adoptium.net](https://adoptium.net) (tick *Set JAVA_HOME variable*) and [nodejs.org](https://nodejs.org). Use **Git Bash** or **PowerShell** for the commands below.

#### SQL Server on Mac

SQL Server has no native Mac version, so it runs in Docker. On Apple Silicon it runs through Rosetta emulation.

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/). In **Settings → General**, turn on **Use Rosetta for x86_64/amd64 emulation on Apple Silicon**, then apply and restart.
2. Start SQL Server (single quotes keep zsh from misreading `!` in the password):

   ```bash
   docker run --platform linux/amd64 \
     -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=<YourStrong!Passw0rd>' \
     -p 1433:1433 --name bizkit-sql \
     -v bizkit-sql-data:/var/opt/mssql \
     -d mcr.microsoft.com/mssql/server:2022-latest
   ```

   After the first run, start it again with `docker start bizkit-sql`.
3. Connect with either client, using server `localhost`, port `1433`, user `sa` and your password:
   - **VS Code:** install the **SQL Server (mssql)** extension and add a connection (tick *Trust server certificate*).
   - **DBeaver:** New Connection → SQL Server.

#### SQL Server on Windows

1. Install **SQL Server Developer edition** (free) with a **default instance**. When asked for authentication, choose **Mixed Mode** and set an `sa` password; the backend logs in with a SQL login, not Windows authentication.
2. In **SQL Server Configuration Manager**, make sure **TCP/IP** is enabled for the instance, then restart the SQL Server service.
3. Install **SQL Server Management Studio (SSMS)** and connect to `localhost` with SQL Server Authentication (tick *Trust server certificate*).

Check the installs in a new terminal window:

```bash
git --version
java -version
node -v
```

### 1. Clone the repository

```bash
git clone https://github.com/<org-or-user>/bizkit.git
cd bizkit
```

### 2. Set up the database

Make sure the database server is running, then run the scripts in order with your SQL client. The first script can be re-run safely; it drops existing objects before recreating them.

1. `database/dist/01_create_schema.sql` – creates the `bizkit` database and all tables
2. `database/dist/02_insert_seed_data.sql` – loads the menu, tables, staff and demo checks

Open each file and run the whole script:

- **VS Code (mssql extension):** open the file, choose your connection, then **Execute Query**.
- **DBeaver:** open the file in a SQL editor and use **Execute SQL Script** (Alt+X), not *Execute statement*.
- **SSMS:** File → Open → File, then **Execute** (F5).

Scripts use `GO` between batches, which all three clients understand.

### 3. Configure environment variables

Copy each template and fill in your own values. The `.env` files are ignored by Git, so credentials are never committed.

**Mac / Git Bash:**

```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

**Windows PowerShell:**

```powershell
Copy-Item backend\.env.example backend\.env
Copy-Item frontend\.env.example frontend\.env
```

| File | Keys |
| --- | --- |
| `backend/.env` | `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` |

For a local SQL Server, `DB_URL` looks like:

```
DB_URL=jdbc:sqlserver://localhost:1433;databaseName=bizkit;encrypt=true;trustServerCertificate=true
```
| `frontend/.env` | `VITE_API_BASE_URL` (default `http://localhost:8080/api`) |

### 4. Run the backend

**In Eclipse (Mac and Windows):** File → Import → Maven → Existing Maven Projects → select the `backend` folder, then right-click `BizkitApplication` → Run As → Java Application.

**From a terminal:**

```bash
# Mac
cd backend
chmod +x mvnw        # first time only
./mvnw spring-boot:run
```

```powershell
# Windows PowerShell
cd backend
.\mvnw.cmd spring-boot:run
```

The API starts on `http://localhost:8080` once the console shows `Started BizkitApplication`.

### 5. Run the frontend

In a second terminal (same on Mac and Windows):

```bash
cd frontend
npm install
npm run dev
```

Open the URL shown in the terminal (usually `http://localhost:5173`).

See `RUN_INSTRUCTIONS.txt` for troubleshooting.

## Demo walkthrough

The seed data sets up each scenario so it can be demonstrated right away.

1. **Take an order** – Open the Take Order tab, pick a table, open Burgers, choose Classic Burger, add Cheese and Bacon and watch the price update. Remove an item, then press Undo.
2. **Fix it on the floor** – On the Tables tab, select the chicken parm and carbonara and move them to course 1. Move items to a table with one check and watch them merge. Move items to Table 5, which has two checks, and choose where they go.
3. **Close the shift** – On the Close Shift tab, press Close shift, accept the carry-over prompt, then sort the report by quantity or revenue.

## Team

| Member | Data structure | Backend | Frontend | Database |
| --- | --- | --- | --- | --- |
| Carolina (database lead) | MenuTree (`adt/tree`) | `menu/`, `order/` | `features/order/` | `01_foundation/`, `02_menu/`, build script, pre-deployment |
| Tolu | List + Iterator (`adt/list`) | `floor/` | `features/floor/` | `03_checks_orders/`, `04_floor_operations/` |
| Vigneshwar | Stack (`adt/stack`) | `shift/`, `undo/`, `sorting/` | `features/shift/` | `05_payments/`, `06_shift_close/` |

Each person owns the matching seed file in `scripts/post-deployment/` for their domains.

## Database workflow

The database source is split into one file per table so everyone can build and test their own objects without editing the same files. A build script combines them into the two graded files in `database/dist/`.

**Domains and build order.** Folders and files are numbered so the build runs parents before children:

| Folder | Tables |
| --- | --- |
| `01_foundation/` | SERVICE_AREA, DINING_TABLE, COURSE, EMPLOYEE, SERVER, MANAGER, SHIFT |
| `02_menu/` | MENU_ENTRY, CATEGORY, MENU_ITEM, ADD_ON |
| `03_checks_orders/` | GUEST_CHECK, ORDER_ITEM, ORDER_ITEM_ADD_ON |
| `04_floor_operations/` | ITEM_TRANSFER |
| `05_payments/` | PAYMENT, CARD_PAYMENT, CASH_PAYMENT |
| `06_shift_close/` | SHIFT_CARRYOVER |

Name files with a number and the table name, for example `01_foundation/02_dining_table.sql`, so they sort into dependency order.

**What the build produces.**

- `dist/01_create_schema.sql` = `pre-deployment/` (DROP IF EXISTS for every object, children first, then CREATE DATABASE) + every file in `src/tables/` in order + `src/programmability/` + `src/indexes/`
- `dist/02_insert_seed_data.sql` = every file in `scripts/post-deployment/` in order

**Run the build:**

```bash
# Mac (Terminal) and Windows (Git Bash, installed with Git)
bash database/scripts/build_dist.sh
```

Then run both files in `dist/` against your local server and run the queries in `tests/` (row counts, foreign-key checks and the demo states, such as Table 5 having two open checks).

**Rules.**

- Adding a table means adding its file in your domain folder **and** a line in `pre-deployment/drop_all_objects.sql`, in children-first order.
- Feature pull requests change `src/` and `scripts/` only. **Never edit `dist/` by hand.** After merging to `main`, rebuild `dist/` and commit it on its own ("Rebuild dist").
- Report sorting and category totals stay in the Java ADTs. Don't move them into views or stored procedures.
- **SQL Server specifics:** the build script puts `GO` between files, because `CREATE TRIGGER` and `CREATE VIEW` must each start their own batch. Before `DROP DATABASE`, the pre-deployment script sets the database to single-user mode so open connections (such as a running backend) don't block the drop.

## Contributing

- **Branches:** work on a feature branch named after your part, for example `feature/menu-tree`, `feature/floor` or `feature/shift`.
- **Pull requests:** `main` is protected. Open a pull request when your change builds and its tests pass; CODEOWNERS requests a review from the folder's owner.
- **Shared files:** `pom.xml`, `package.json`, `App.jsx`, `BizkitApplication.java`, `common/`, `database/scripts/pre-deployment/` and `docs/api.md` belong to everyone. Change them in small, separate pull requests and mention it in the group chat.
- **API changes:** update `docs/api.md` in the same pull request as the endpoint change.
- **Data structures:** code in `adt/` must not import `java.util` collections.

## Documentation

- `docs/design-doc.pdf` – full design: issues, features, requirements, data model and team workflow
- `docs/erd.png` – logical data model (EER)
- `docs/wireframes/` – screen wireframes for all three scenarios
- `docs/api.md` – REST endpoint contract: conventions, shared JSON shapes, endpoint index and a template for each endpoint
