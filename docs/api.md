# Bizkit API contract

This file is the agreement between the React frontend and the Java backend. Both sides build against it, so a change here comes first, in its own pull request, reviewed by the endpoint's owner **and** the owner of the screen that calls it.

**Status key:** `Draft` (shape proposed) → `Agreed` (both sides signed off) → `Built` (backend endpoint works)

---

## 1. Conventions

These apply to every endpoint unless the endpoint says otherwise.

| Topic | Convention |
| --- | --- |
| Base URL | `http://localhost:8080/api` (frontend reads it from `VITE_API_BASE_URL`) |
| Paths | Plural nouns, lowercase, hyphens for multi-word actions: `/checks/{checkId}/items/move-course` |
| JSON fields | camelCase: `orderItemId`, `tableNumber` |
| IDs | Integers, matching the primary keys in the ERD |
| Money | **Integer cents**, and the field name ends in `Cents`: `1350` = $13.50 (`unitPriceCents`, `totalCents`). The frontend only formats it for display. Java code also uses `int` cents; repositories convert to and from `DECIMAL(8,2)`. |
| Dates and times | ISO 8601 strings: `"2026-12-02T18:30:00"` |
| Status values | Uppercase words, never the single letters stored in the database: `"OPEN"`, `"PAID"`, `"CLOSED"`, `"HELD"`, `"SENT"` |
| Lists | `GET` endpoints that return a list return a plain JSON array, not an object around it |
| Empty lists | Always `[]`, never `null` |
| Optional fields | Present with `null` when there is no value |
| Who computes | The backend computes all prices, totals, sorting and grouping (that's where our ADTs and algorithms live). The frontend never sums or sorts data itself. |
| Changes | Any request that changes data returns the `ChangeResult` shape (section 2) so the frontend can redraw without another request. |
| Who made the change | The app has no login. Actions on a check (moves, splits, payments) are recorded under the check's server. Actions with no check (opening a check, closing the shift) send the `employeeId` of the person shown in the top bar. |

### Errors

Every error uses the same body:

```json
{
  "error": {
    "code": "CHECK_NOT_FOUND",
    "message": "Check 42 does not exist."
  }
}
```

| HTTP status | When |
| --- | --- |
| `400 Bad Request` | Missing or invalid input (empty item list, unknown course) |
| `404 Not Found` | An ID in the path or body doesn't exist |
| `409 Conflict` | The request is valid but can't be applied in the current state (paying an already paid check, nothing to undo) |
| `500 Internal Server Error` | Unexpected failure; message is generic |

**Error codes** (add new ones here as you create them):

| Code | Status | Meaning |
| --- | --- | --- |
| `VALIDATION_FAILED` | 400 | A field is missing or invalid |
| `TABLE_NOT_FOUND` | 404 | |
| `CHECK_NOT_FOUND` | 404 | |
| `ITEM_NOT_FOUND` | 404 | An order item doesn't exist |
| `MENU_ENTRY_NOT_FOUND` | 404 | A menu entry (category, item or add-on) doesn't exist |
| `EMPLOYEE_NOT_FOUND` | 404 | |
| `SHIFT_NOT_FOUND` | 404 | |
| `CHECK_ALREADY_PAID` | 409 | The check is paid; also returned by Undo when the last action touched a now-paid check |
| `CHECK_CLOSED` | 409 | The check was emptied by a move and closed, so it can't be changed |
| `ITEM_UNAVAILABLE` | 409 | The menu item is marked unavailable (sold out) |
| `ITEM_ALREADY_SENT` | 409 | The item was already sent to the kitchen, so it can't be removed |
| `NOTHING_TO_UNDO` | 409 | The undo stack is empty |
| `OPEN_CHECKS_REMAIN` | 409 | The shift has open checks and the request didn't ask to carry them over |
| `SHIFT_ALREADY_CLOSED` | 409 | |

---

## 2. Shared shapes

Screens reuse these shapes. **Never return a different version of the same thing.** If an endpoint needs extra fields, add them here so every screen sees the same shape.

### Check

| Field | Type | Notes |
| --- | --- | --- |
| `checkId` | int | |
| `tableId` | int | |
| `tableNumber` | int | |
| `checkLabel` | string | `"Check 1"`, `"Check 2"` within its table |
| `serverName` | string | |
| `guestCount` | int | |
| `status` | string | `OPEN`, `PAID`, `CLOSED` |
| `courses` | Course[] | Always all courses, in course order, even if empty |
| `totalCents` | int | Computed by the backend |
| `openedAt` | string | ISO 8601 |

### Course (inside a Check)

| Field | Type | Notes |
| --- | --- | --- |
| `courseId` | int | |
| `courseNumber` | int | 1, 2, 3 |
| `courseName` | string | `"Apps"`, `"Mains"`, `"Dessert"` |
| `items` | OrderItem[] | In display order |

### OrderItem

| Field | Type | Notes |
| --- | --- | --- |
| `orderItemId` | int | |
| `menuItemId` | int | |
| `name` | string | |
| `quantity` | int | |
| `addOns` | AddOnChoice[] | |
| `unitPriceCents` | int | Item price plus add-ons, at time of order |
| `lineTotalCents` | int | `unitPriceCents × quantity` |
| `status` | string | `HELD`, `SENT` |
| `specialRequest` | string or null | |
| `movedFrom` | string or null | For the merge tag, e.g. `"Merged from Table 2"` |

### AddOnChoice

| Field | Type | Notes |
| --- | --- | --- |
| `addOnId` | int | |
| `name` | string | |
| `priceCents` | int | |

### MenuNode

Recursive: the whole menu tree arrives in one response.

| Field | Type | Notes |
| --- | --- | --- |
| `entryId` | int | |
| `name` | string | |
| `type` | string | `CATEGORY`, `ITEM`, `ADD_ON` |
| `priceCents` | int or null | Null for categories |
| `defaultCourseId` | int or null | Items only |
| `isAvailable` | boolean | Items only; `true` for other types |
| `children` | MenuNode[] | Empty for add-ons |

### TableSummary

| Field | Type | Notes |
| --- | --- | --- |
| `tableId` | int | |
| `tableNumber` | int | |
| `areaName` | string | |
| `openCheckCount` | int | |
| `openTotalCents` | int | |

### UndoState

| Field | Type | Notes |
| --- | --- | --- |
| `canUndo` | boolean | |
| `label` | string or null | Shown on the top-bar button, e.g. `"Merged 2 items"` |

### ChangeResult

Returned by every endpoint that changes data.

| Field | Type | Notes |
| --- | --- | --- |
| `checks` | Check[] | Every check the change touched, in its new state |
| `removedCheckIds` | int[] | Checks the change closed (emptied by a move, or a split check undone). They are `CLOSED`, not deleted, and leave the table's list |
| `undo` | UndoState | The top-bar button after the change |
| `message` | string | Snackbar text, e.g. `"Merged 2 items into Table 4's check"` |

### ShiftSummary, ReportRow, CategoryTotal, SortTiming

| Shape | Fields |
| --- | --- |
| ShiftSummary | `shiftId` int, `shiftName` string, `status` string (`OPEN`, `CLOSED`), `paidCheckCount` int, `paidTotalCents` int, `openChecks` Check[] |
| ReportRow | `rank` int, `menuItemId` int, `name` string, `quantity` int, `revenueCents` int |
| CategoryTotal | `entryId` int, `name` string, `revenueCents` int |
| SortTiming | `algorithm` string, `itemCount` int, `elapsedMicros` int |

---

## 3. Endpoint index

| Method | Path | Owner | Screen | Status |
| --- | --- | --- | --- | --- |
| GET | `/menu` | Carolina | Take Order | Agreed |
| GET | `/menu/items/{entryId}/price` | Carolina | Take Order | Agreed |
| POST | `/checks` | Carolina | Take Order | Agreed |
| POST | `/checks/{checkId}/items` | Carolina | Take Order | Agreed |
| DELETE | `/checks/{checkId}/items/{orderItemId}` | Carolina | Take Order | Agreed |
| POST | `/checks/{checkId}/send` | Carolina | Take Order | Agreed |
| GET | `/tables` | Tolu | Tables | Agreed |
| GET | `/tables/{tableId}/checks` | Tolu | Tables, Take Order | Agreed |
| POST | `/checks/{checkId}/items/move-course` | Tolu | Tables | Agreed |
| POST | `/items/move-table` | Tolu | Tables | Agreed |
| POST | `/checks/{checkId}/split` | Tolu | Tables | Agreed |
| POST | `/checks/{checkId}/payments` | Tolu | Tables | Agreed |
| GET | `/undo` | Vigneshwar | All (top bar) | Draft (Vigneshwar to review) |
| POST | `/undo` | Vigneshwar | All (top bar) | Draft (Vigneshwar to review) |
| GET | `/shifts/current/summary` | Vigneshwar | Close Shift | Draft (Vigneshwar to review) |
| POST | `/shifts/current/close` | Vigneshwar | Close Shift | Draft (Vigneshwar to review) |
| GET | `/shifts/{shiftId}/report` | Vigneshwar | Close Shift | Draft (Vigneshwar to review) |
| GET | `/shifts/{shiftId}/sort-timing` | Vigneshwar | Close Shift | Draft (Vigneshwar to review) |

---

## 4. Endpoints

Copy this template for each new endpoint and fill in every part. Delete nothing; write "None" where a part doesn't apply.

```markdown
### METHOD /path

**Owner:** Name · **Called by:** Screen · **Status:** Draft

What it does, in one sentence.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |

**Request body**

(JSON example, or "None")

**Success response** – `200 OK`

(JSON example using the shared shapes)

**Errors**

| Status | Code | When |
| --- | --- | --- |

**Rules and notes**

(Behaviour the frontend relies on, edge cases, which ADT or algorithm runs here)
```

---

<!-- Menu and order endpoints (Carolina). -->

### GET /menu

**Owner:** Carolina · **Called by:** Take Order · **Status:** Agreed

Returns the whole menu as one tree, for the menu browser.

**Path / query parameters**

None

**Request body**

None

**Success response** – `200 OK`

The root MenuNode. Its children are the top-level menus (Food, Drinks), then groups, items and add-ons.

```json
{
  "entryId": 1, "name": "Menu", "type": "CATEGORY", "priceCents": null,
  "defaultCourseId": null, "isAvailable": true,
  "children": [
    {
      "entryId": 2, "name": "Food", "type": "CATEGORY", "priceCents": null,
      "defaultCourseId": null, "isAvailable": true,
      "children": [
        {
          "entryId": 11, "name": "Burgers", "type": "CATEGORY", "priceCents": null,
          "defaultCourseId": null, "isAvailable": true,
          "children": [
            {
              "entryId": 40, "name": "Classic Burger", "type": "ITEM", "priceCents": 1200,
              "defaultCourseId": 2, "isAvailable": true,
              "children": [
                { "entryId": 41, "name": "Cheese", "type": "ADD_ON", "priceCents": 150, "defaultCourseId": null, "isAvailable": true, "children": [] },
                { "entryId": 42, "name": "Bacon", "type": "ADD_ON", "priceCents": 200, "defaultCourseId": null, "isAvailable": true, "children": [] },
                { "entryId": 43, "name": "Avocado", "type": "ADD_ON", "priceCents": 250, "defaultCourseId": null, "isAvailable": true, "children": [] }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 500 | | Unexpected failure only; this endpoint has no expected errors |

**Rules and notes**

- Built by a recursive walk of the MenuTree from the root, visiting children in `displayOrder`.
- Unavailable items are included with `isAvailable: false`, so the frontend can grey them out instead of hiding them.
- The menu is loaded into the MenuTree once at startup; this endpoint doesn't query the database.

---

### GET /menu/items/{entryId}/price

**Owner:** Carolina · **Called by:** Take Order · **Status:** Agreed

Returns the price of one item with the chosen add-ons, for the live price in the modifier panel.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `entryId` | int | Yes | Must be an `ITEM` |
| `addOnIds` | int list | No | Comma-separated, e.g. `?addOnIds=41,42`. Omit for no add-ons |

**Request body**

None

**Success response** – `200 OK`

```json
{
  "entryId": 40,
  "name": "Classic Burger",
  "basePriceCents": 1200,
  "addOns": [
    { "addOnId": 41, "name": "Cheese", "priceCents": 150 },
    { "addOnId": 42, "name": "Bacon", "priceCents": 200 }
  ],
  "unitPriceCents": 1550
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `entryId` isn't an item, or an add-on in `addOnIds` doesn't belong to this item |
| 404 | `MENU_ENTRY_NOT_FOUND` | `entryId` or an add-on ID doesn't exist |

**Rules and notes**

- `unitPriceCents` comes from `MenuTreeInterface.priceWithAddOns`, which adds the item's price to the price of each chosen add-on recursively.
- Repeating an add-on ID counts it once.
- This endpoint only calculates; it changes nothing.

---

### POST /checks

**Owner:** Carolina · **Called by:** Take Order · **Status:** Agreed

Opens a new, empty check on a table.

**Path / query parameters**

None

**Request body**

```json
{
  "tableId": 2,
  "serverId": 3,
  "guestCount": 2
}
```

| Field | Notes |
| --- | --- |
| `serverId` | The employee shown in the top bar; must be a SERVER |
| `guestCount` | 1 or more |

**Success response** – `200 OK`

ChangeResult with the new check: status `OPEN`, every course present and empty, `totalCents: 0`.

```json
{
  "checks": [ { "checkId": 15, "tableNumber": 2, "checkLabel": "Check 2", "status": "OPEN", "totalCents": 0, "...": "Check shape" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Opened Check 2" },
  "message": "Opened Check 2 on Table 2"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `guestCount` is less than 1, or `serverId` isn't a server |
| 404 | `TABLE_NOT_FOUND` | `tableId` doesn't exist |
| 404 | `EMPLOYEE_NOT_FOUND` | `serverId` doesn't exist |

**Rules and notes**

- The check is added to the end of the table's List of checks and recorded in the current shift.
- One Undo entry. Undo closes the check, but only if it's still empty; otherwise Undo refuses with `VALIDATION_FAILED` and discards the entry.

---

### POST /checks/{checkId}/items

**Owner:** Carolina · **Called by:** Take Order · **Status:** Agreed

Adds a menu item, with add-ons, to a course on a check.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `checkId` | int | Yes | |

**Request body**

```json
{
  "menuItemId": 40,
  "addOnIds": [41, 42],
  "courseId": 2,
  "quantity": 1,
  "specialRequest": null
}
```

| Field | Notes |
| --- | --- |
| `addOnIds` | `[]` for none |
| `courseId` | Optional. If `null`, the item's default course is used; if the item has none (drinks), course 1 |
| `quantity` | 1 or more |

**Success response** – `200 OK`

ChangeResult with the updated check.

```json
{
  "checks": [ { "checkId": 3, "tableNumber": 2, "totalCents": 6550, "...": "Check shape with the burger at the end of Mains" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Added Classic Burger" },
  "message": "Added Classic Burger to Table 2"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `menuItemId` isn't an item, an add-on doesn't belong to it, `courseId` doesn't exist, or `quantity` is less than 1 |
| 404 | `CHECK_NOT_FOUND` | `checkId` doesn't exist |
| 404 | `MENU_ENTRY_NOT_FOUND` | `menuItemId` or an add-on ID doesn't exist |
| 409 | `ITEM_UNAVAILABLE` | The item is sold out |
| 409 | `CHECK_ALREADY_PAID` | The check is paid |
| 409 | `CHECK_CLOSED` | The check is closed |

**Rules and notes**

- `unitPriceCents` is calculated by `priceWithAddOns` and stored on the order line, so later menu price changes don't affect it.
- The item is added to the end of its course's List with status `HELD`.
- One Undo entry. Undo removes the item from the position it was added at.

---

### DELETE /checks/{checkId}/items/{orderItemId}

**Owner:** Carolina · **Called by:** Take Order · **Status:** Agreed

Removes an item that hasn't been sent to the kitchen yet.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `checkId` | int | Yes | |
| `orderItemId` | int | Yes | Must be on this check |

**Request body**

None

**Success response** – `200 OK`

ChangeResult with the updated check.

```json
{
  "checks": [ { "checkId": 3, "tableNumber": 2, "...": "Check shape without the item" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Removed Fries" },
  "message": "Removed Fries from Table 2"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 404 | `CHECK_NOT_FOUND` | `checkId` doesn't exist |
| 404 | `ITEM_NOT_FOUND` | `orderItemId` doesn't exist or isn't on this check |
| 409 | `ITEM_ALREADY_SENT` | The item's status is `SENT` |
| 409 | `CHECK_ALREADY_PAID` | The check is paid |
| 409 | `CHECK_CLOSED` | The check is closed |

**Rules and notes**

- Only `HELD` items can be removed. Removing a sent item is a void, which needs a manager in a real restaurant and is out of scope.
- A check left with no items stays `OPEN`. Unlike a move, the server is still building the order.
- One Undo entry, which keeps the removed item's full data. Undo re-inserts it at its original position in its original course.

---

### POST /checks/{checkId}/send

**Owner:** Carolina · **Called by:** Take Order · **Status:** Agreed

Sends held items to the kitchen.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `checkId` | int | Yes | |

**Request body**

```json
{
  "courseIds": [1]
}
```

`courseIds` is optional. `null` or omitted sends every held item on the check.

**Success response** – `200 OK`

ChangeResult with the updated check.

```json
{
  "checks": [ { "checkId": 3, "tableNumber": 2, "...": "Check shape, course 1 items now SENT" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Removed Fries" },
  "message": "Sent 1 item to the kitchen"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | No held items in the chosen courses, or a `courseId` doesn't exist |
| 404 | `CHECK_NOT_FOUND` | `checkId` doesn't exist |
| 409 | `CHECK_ALREADY_PAID` | The check is paid |
| 409 | `CHECK_CLOSED` | The check is closed |

**Rules and notes**

- Changes item status from `HELD` to `SENT`; nothing moves.
- Not undoable, because the kitchen has already received the ticket. `undo` is returned unchanged.

---

<!-- Floor endpoints (Tolu). -->

### GET /tables

**Owner:** Tolu · **Called by:** Tables · **Status:** Agreed

Returns every dining table with its open-check count and open total, for the table grid.

**Path / query parameters**

None

**Request body**

None

**Success response** – `200 OK`

An array of TableSummary, in table-number order.

```json
[
  { "tableId": 1, "tableNumber": 1, "areaName": "Main dining", "openCheckCount": 0, "openTotalCents": 0 },
  { "tableId": 2, "tableNumber": 2, "areaName": "Main dining", "openCheckCount": 1, "openTotalCents": 5000 },
  { "tableId": 5, "tableNumber": 5, "areaName": "Patio", "openCheckCount": 2, "openTotalCents": 7350 }
]
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 500 | | Unexpected failure only; this endpoint has no expected errors |

**Rules and notes**

- Every table is listed, including tables with no open checks (`openCheckCount: 0`, `openTotalCents: 0`).
- Only `OPEN` checks count. Paid and closed checks are not on a table's list.
- `openTotalCents` is the sum of the open checks' `totalCents`, computed by iterating the table's List of checks with the custom iterator.
- Tables are held in a List ADT, loaded once at startup in table-number order, so no sorting happens per request.

---

### GET /tables/{tableId}/checks

**Owner:** Tolu · **Called by:** Tables, Take Order · **Status:** Agreed

Returns the open checks on one table, with all their courses and items.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `tableId` | int | Yes | |

**Request body**

None

**Success response** – `200 OK`

An array of Check, in `checkLabel` order. Empty array if the table has no open checks.

```json
[
  {
    "checkId": 3,
    "tableId": 2,
    "tableNumber": 2,
    "checkLabel": "Check 1",
    "serverName": "Maya R.",
    "guestCount": 3,
    "status": "OPEN",
    "courses": [
      {
        "courseId": 1, "courseNumber": 1, "courseName": "Apps",
        "items": [
          {
            "orderItemId": 7, "menuItemId": 21, "name": "Caesar salad", "quantity": 1,
            "addOns": [], "unitPriceCents": 1200, "lineTotalCents": 1200,
            "status": "SENT", "specialRequest": null, "movedFrom": null
          }
        ]
      },
      {
        "courseId": 2, "courseNumber": 2, "courseName": "Mains",
        "items": [
          {
            "orderItemId": 8, "menuItemId": 30, "name": "Chicken parm", "quantity": 1,
            "addOns": [], "unitPriceCents": 1950, "lineTotalCents": 1950,
            "status": "HELD", "specialRequest": null, "movedFrom": null
          },
          {
            "orderItemId": 9, "menuItemId": 31, "name": "Carbonara", "quantity": 1,
            "addOns": [], "unitPriceCents": 1850, "lineTotalCents": 1850,
            "status": "HELD", "specialRequest": "No pepper", "movedFrom": null
          }
        ]
      },
      { "courseId": 3, "courseNumber": 3, "courseName": "Dessert", "items": [] }
    ],
    "totalCents": 5000,
    "openedAt": "2026-12-02T11:05:00"
  }
]
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 404 | `TABLE_NOT_FOUND` | `tableId` doesn't exist |

**Rules and notes**

- Only `OPEN` checks are returned.
- `checkLabel` comes from the check's position in the table's List: the first open check is `"Check 1"`, the second `"Check 2"`. Labels can change after a merge or split, so the frontend uses `checkId`, never the label, to identify a check.
- Every check lists all courses in course order, even empty ones, as the shared Check shape requires.
- Items without a default course (drinks) are placed in course 1 when added (see `POST /checks/{checkId}/items`).

---

### POST /checks/{checkId}/items/move-course

**Owner:** Tolu · **Called by:** Tables · **Status:** Agreed

Moves several selected items on one check to another course in one action (coworker issue 1).

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `checkId` | int | Yes | The check the items are on |

**Request body**

```json
{
  "orderItemIds": [8, 9],
  "targetCourseId": 1
}
```

**Success response** – `200 OK`

ChangeResult.

```json
{
  "checks": [ { "checkId": 3, "tableNumber": 2, "...": "Check shape, parm and carbonara now in course 1" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Moved 2 items to Apps" },
  "message": "Moved 2 items to Apps"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `orderItemIds` is empty, `targetCourseId` doesn't exist, or every selected item is already in the target course |
| 404 | `CHECK_NOT_FOUND` | `checkId` doesn't exist |
| 404 | `ITEM_NOT_FOUND` | An ID in `orderItemIds` doesn't exist or isn't on this check |
| 409 | `CHECK_ALREADY_PAID` | The check is paid |
| 409 | `CHECK_CLOSED` | The check is closed |

**Rules and notes**

- Selected items can come from different courses. Items already in the target course stay where they are; the rest move.
- For each source course, the service finds the selected positions while iterating (so they come out in ascending order), then removes them from the highest position down, so earlier removals don't shift later ones.
- Moved items are added to the end of the target course, keeping their original relative order.
- Each moved item gets one ITEM_TRANSFER row with `fromCheckId` = `toCheckId` and its old and new course. `movedFrom` is not set for a course move.
- Item status (`HELD` or `SENT`) doesn't change.
- The whole action is one Undo entry. Undo puts each item back in its original course at its original position, inserting in ascending position order.

---

### POST /items/move-table

**Owner:** Tolu · **Called by:** Tables · **Status:** Agreed

Moves selected items to another table, following the auto-merge rules (coworker issue 2).

**Path / query parameters**

None

**Request body**

```json
{
  "orderItemIds": [12, 13],
  "targetTableId": 5,
  "targetCheckId": null
}
```

| Field | Notes |
| --- | --- |
| `orderItemIds` | All must be on the same source check |
| `targetTableId` | The table the items should end up on |
| `targetCheckId` | `null` on the first call. A check ID on the target table when the user picked one in the dialog, or `-1` for "a new separate check" |

**Success response** – `200 OK`

ChangeResult plus `result` and `options`.

Merged into the only check on Table 4:

```json
{
  "result": "MERGED",
  "options": [],
  "checks": [
    { "checkId": 7, "tableNumber": 4, "...": "Check shape, moved items tagged Merged from Table 2" }
  ],
  "removedCheckIds": [3],
  "undo": { "canUndo": true, "label": "Merged 2 items" },
  "message": "Merged 2 items into Table 4's check"
}
```

Table 5 has two checks, so nothing moved yet:

```json
{
  "result": "CHOOSE_CHECK",
  "options": [
    { "checkId": 10, "tableNumber": 5, "checkLabel": "Check 1", "...": "Check shape" },
    { "checkId": 11, "tableNumber": 5, "checkLabel": "Check 2", "...": "Check shape" }
  ],
  "checks": [],
  "removedCheckIds": [],
  "undo": { "canUndo": false, "label": null },
  "message": "Table 5 has 2 checks. Choose one."
}
```

| `result` | Meaning |
| --- | --- |
| `NEW_CHECK` | Target table had no open checks, or `targetCheckId` was `-1`; the items became a new check there |
| `MERGED` | Target had one open check, or the user chose one; the items merged into it |
| `CHOOSE_CHECK` | Target has several open checks and `targetCheckId` was `null`. **Nothing moved.** `options` lists the candidate checks in label order; the frontend shows the dialog (wireframe 2.4) with the first option preselected, then calls again with the chosen `targetCheckId` |

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `orderItemIds` is empty, the items are on more than one check, the target is the items' current table, or `targetCheckId` isn't an open check on the target table |
| 404 | `TABLE_NOT_FOUND` | `targetTableId` doesn't exist |
| 404 | `ITEM_NOT_FOUND` | Any ID in `orderItemIds` doesn't exist |
| 409 | `CHECK_ALREADY_PAID` | The source check is paid |
| 409 | `CHECK_CLOSED` | The source check is closed |

**Rules and notes**

- Moved items keep their course and are added to the end of that course on the target check.
- Each moved item's `movedFrom` becomes `"Merged from Table 2"` (MERGED) or `"Moved from Table 2"` (NEW_CHECK), using the source table's number.
- A new check (NEW_CHECK) gets the source check's server and guest count and the current shift.
- A source check left with no items is set to `CLOSED`, not deleted, because ITEM_TRANSFER rows still point to it. Its ID is returned in `removedCheckIds`.
- Each moved item gets one ITEM_TRANSFER row (source check to target check, same course).
- `CHOOSE_CHECK` changes nothing, so its `undo` is the current state, unchanged.
- The whole move is one Undo entry. Undo moves the items back to their original check, course and positions, and reopens a source check that was closed.
- Items are removed from each source course List from the highest position down, so positions don't shift.

---

### POST /checks/{checkId}/split

**Owner:** Tolu · **Called by:** Tables · **Status:** Agreed

Moves selected items into a new check on the same table, for guests who pay separately.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `checkId` | int | Yes | The check the items come from |

**Request body**

```json
{
  "orderItemIds": [9]
}
```

**Success response** – `200 OK`

ChangeResult with both checks: the original first, then the new one.

```json
{
  "checks": [
    { "checkId": 3, "tableNumber": 2, "checkLabel": "Check 1", "...": "Check shape without the carbonara" },
    { "checkId": 14, "tableNumber": 2, "checkLabel": "Check 2", "...": "Check shape with the carbonara" }
  ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Split 1 item" },
  "message": "Split 1 item into Check 2"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `orderItemIds` is empty, or it contains every item on the check (nothing would be left) |
| 404 | `CHECK_NOT_FOUND` | `checkId` doesn't exist |
| 404 | `ITEM_NOT_FOUND` | An ID in `orderItemIds` doesn't exist or isn't on this check |
| 409 | `CHECK_ALREADY_PAID` | The check is paid |
| 409 | `CHECK_CLOSED` | The check is closed |

**Rules and notes**

- The new check is added to the end of the table's List of checks, with the same server, a guest count of 1 and the current shift.
- Items keep their course and their relative order.
- `movedFrom` becomes `"Split from Check 1"`, using the original check's label.
- Each moved item gets one ITEM_TRANSFER row.
- The whole split is one Undo entry. Undo moves the items back to their original positions and closes the new check.

---

### POST /checks/{checkId}/payments

**Owner:** Tolu · **Called by:** Tables · **Status:** Agreed

Records a payment on a check, and marks the check paid once its total is covered.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `checkId` | int | Yes | |

**Request body**

```json
{
  "paymentType": "CARD",
  "amountCents": 5000,
  "tipCents": 900,
  "cardLastFour": "4242",
  "authCode": "A1B2C3",
  "amountTenderedCents": null
}
```

| Field | Notes |
| --- | --- |
| `paymentType` | `CARD`, `CASH` or `OTHER` |
| `amountCents` | Toward the check total, without the tip. Can be less than the balance (split tender: card plus cash) |
| `tipCents` | `0` if none |
| `cardLastFour`, `authCode` | Required for `CARD`, `null` otherwise. The full card number is never sent |
| `amountTenderedCents` | Required for `CASH`: what the guest handed over. `null` otherwise |

**Success response** – `200 OK`

ChangeResult plus `payment` and `warning`.

```json
{
  "payment": {
    "paymentId": 4,
    "paymentType": "CARD",
    "amountCents": 5000,
    "tipCents": 900,
    "changeDueCents": 0,
    "remainingCents": 0
  },
  "warning": {
    "code": "OTHER_OPEN_CHECKS",
    "openCheckCount": 1,
    "message": "Table 5 still has 1 open check."
  },
  "checks": [ { "checkId": 10, "tableNumber": 5, "status": "PAID", "...": "Check shape" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Merged 2 items" },
  "message": "Check 1 paid"
}
```

| Field | Notes |
| --- | --- |
| `payment.changeDueCents` | `amountTenderedCents - amountCents - tipCents` for cash, `0` otherwise. Computed, not stored |
| `payment.remainingCents` | Balance still owed after this payment. `0` means the check is now `PAID` |
| `warning` | `null` unless the check became `PAID` and other checks on the same table are still open |

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | Unknown `paymentType`; `amountCents` is 0 or less or more than the balance; `tipCents` is negative; card fields missing for `CARD`; `amountTenderedCents` missing or too small for `CASH` |
| 404 | `CHECK_NOT_FOUND` | `checkId` doesn't exist |
| 409 | `CHECK_ALREADY_PAID` | The check is already paid |
| 409 | `CHECK_CLOSED` | The check is closed |

**Rules and notes**

- The payment is recorded in the current shift, so the shift report counts it there.
- When payments cover the total, the check becomes `PAID`, `closedAt` is set, and it moves from the table's List of checks to the shift's paid List. The Tables screen drops it from the table; Close Shift counts it.
- The open-checks warning is found by iterating the table's remaining checks with the custom iterator.
- Payments are not undoable, so `undo` is returned unchanged. Reversing a payment would be a refund, which is out of scope (see 5.4).

---

<!-- Undo and shift endpoints (Vigneshwar). Drafted by Carolina; Vigneshwar to review. -->

### GET /undo

**Owner:** Vigneshwar · **Called by:** All (top bar) · **Status:** Draft (Vigneshwar to review)

Returns the current state of the Undo button.

**Path / query parameters**

None

**Request body**

None

**Success response** – `200 OK`

UndoState.

```json
{ "canUndo": true, "label": "Merged 2 items" }
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 500 | | Unexpected failure only; this endpoint has no expected errors |

**Rules and notes**

- `label` is the label of the entry on top of the Undo stack (`peek`), or `null` when the stack is empty.
- The frontend calls it on page load and after any Undo error. Every other change already returns `undo` in its ChangeResult.

---

### POST /undo

**Owner:** Vigneshwar · **Called by:** All (top bar) · **Status:** Draft (Vigneshwar to review)

Reverses the most recent undoable action.

**Path / query parameters**

None

**Request body**

None

**Success response** – `200 OK`

ChangeResult with every check the undo touched.

```json
{
  "checks": [
    { "checkId": 3, "tableNumber": 2, "status": "OPEN", "...": "Check shape, items back in place" },
    { "checkId": 7, "tableNumber": 4, "...": "Check shape without the moved items" }
  ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Moved 2 items to Apps" },
  "message": "Undid: Merged 2 items"
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 409 | `NOTHING_TO_UNDO` | The Undo stack is empty |
| 409 | `CHECK_ALREADY_PAID` | The action touched a check that has since been paid. The entry is discarded, so the next Undo moves on to the action before it |
| 409 | `VALIDATION_FAILED` | The action can no longer be reversed (for example, undoing "Opened Check 2" after items were added). The entry is discarded |

**Rules and notes**

- Pops the top entry from the Undo stack and hands it to the service that owns that action type (section 5.2).
- A check closed by the undo (for example, the new check from an undone split) is returned in `removedCheckIds`. A check reopened by the undo appears in `checks` with status `OPEN`.
- Undoing a move writes reversing ITEM_TRANSFER rows, so the move history stays complete.
- After any error, the frontend calls `GET /undo` to refresh the button.
- The Undo stack is cleared when the shift closes.

---

### GET /shifts/current/summary

**Owner:** Vigneshwar · **Called by:** Close Shift · **Status:** Draft (Vigneshwar to review)

Returns the open shift's paid totals and its open checks, for the summary cards.

**Path / query parameters**

None

**Request body**

None

**Success response** – `200 OK`

ShiftSummary.

```json
{
  "shiftId": 1,
  "shiftName": "Brunch",
  "status": "OPEN",
  "paidCheckCount": 2,
  "paidTotalCents": 6100,
  "openChecks": [
    { "checkId": 3, "tableNumber": 2, "checkLabel": "Check 1", "totalCents": 5000, "...": "Check shape" },
    { "checkId": 10, "tableNumber": 5, "checkLabel": "Check 1", "totalCents": 3000, "...": "Check shape" }
  ]
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 500 | | Unexpected failure only; there is always an open shift |

**Rules and notes**

- `paidCheckCount` and `paidTotalCents` come from iterating the shift's paid List. `paidTotalCents` excludes tips.
- `openChecks` lists every open check, table by table in table-number order, then by label, by iterating the tables List and each table's checks.

---

### POST /shifts/current/close

**Owner:** Vigneshwar · **Called by:** Close Shift · **Status:** Draft (Vigneshwar to review)

Closes the open shift, carrying any open checks over to a new shift (coworker issue 3).

**Path / query parameters**

None

**Request body**

```json
{
  "carryOver": true,
  "employeeId": 1,
  "nextShiftName": "Dinner"
}
```

| Field | Notes |
| --- | --- |
| `carryOver` | Must be `true` if the shift has open checks. The frontend first sends `false`; a `409 OPEN_CHECKS_REMAIN` tells it to show the carry-over prompt |
| `employeeId` | The employee shown in the top bar. Recorded as the shift's closer and on each carry-over row |
| `nextShiftName` | Name of the shift that opens next |

**Success response** – `200 OK`

ChangeResult plus the closed and new shift IDs.

```json
{
  "closedShiftId": 1,
  "nextShiftId": 2,
  "carriedOverCheckIds": [3, 10, 11],
  "checks": [ { "checkId": 3, "tableNumber": 2, "status": "OPEN", "...": "Check shape" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": false, "label": null },
  "message": "Brunch closed. 3 open checks carried over to Dinner."
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `nextShiftName` is empty |
| 404 | `EMPLOYEE_NOT_FOUND` | `employeeId` doesn't exist |
| 409 | `OPEN_CHECKS_REMAIN` | The shift has open checks and `carryOver` is `false`. Nothing changes |
| 409 | `SHIFT_ALREADY_CLOSED` | The shift was already closed, for example by a second click |

**Rules and notes**

- Writes one SHIFT_CARRYOVER row per open check, with `confirmedByEmployeeId`. Open checks stay on their tables, unchanged.
- Sets the shift's `closedAt` and `closedByEmployeeId`, then opens the next shift.
- The report for the closed shift counts only checks paid during it (`GET /shifts/{closedShiftId}/report`).
- Not undoable. The Undo stack is cleared, so the new shift starts clean.

---

### GET /shifts/{shiftId}/report

**Owner:** Vigneshwar · **Called by:** Close Shift · **Status:** Draft (Vigneshwar to review)

Returns the shift's sales report: items sorted by quantity or revenue, and totals per menu category.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `shiftId` | int | Yes | Usually `closedShiftId` from the close response |
| `sortBy` | string | No | `quantity` (default) or `revenue` |
| `algorithm` | string | No | `merge` (default) or `insertion` |

**Request body**

None

**Success response** – `200 OK`

```json
{
  "shiftId": 1,
  "shiftName": "Brunch",
  "status": "CLOSED",
  "sortBy": "quantity",
  "algorithm": "merge",
  "paidCheckCount": 2,
  "paidTotalCents": 6100,
  "rows": [
    { "rank": 1, "menuItemId": 50, "name": "Soda", "quantity": 2, "revenueCents": 600 },
    { "rank": 2, "menuItemId": 32, "name": "Salmon", "quantity": 1, "revenueCents": 1900 },
    { "rank": 3, "menuItemId": 40, "name": "Classic Burger", "quantity": 1, "revenueCents": 1400 }
  ],
  "categoryTotals": [
    { "entryId": 10, "name": "Starters", "revenueCents": 900 },
    { "entryId": 11, "name": "Burgers", "revenueCents": 1400 },
    { "entryId": 12, "name": "Mains", "revenueCents": 1900 }
  ]
}
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `sortBy` or `algorithm` isn't one of the allowed values |
| 404 | `SHIFT_NOT_FOUND` | `shiftId` doesn't exist |

**Rules and notes**

- Built in Java, never in SQL: iterate the shift's paid checks and their items, and add each item's `quantity` and `lineTotalCents` (add-ons included) to its row in a List of report rows.
- Rows are sorted with the team's own sorting algorithm, descending by `sortBy`; ties go to the other measure, then to name A–Z. `rank` is assigned after sorting.
- `categoryTotals` comes from `MenuTreeInterface.categoryTotals`: one entry for every category that directly holds items, in menu display order, with zero-revenue categories left out.
- Works for open and closed shifts. For an open shift it shows what's been paid so far.

---

### GET /shifts/{shiftId}/sort-timing

**Owner:** Vigneshwar · **Called by:** Close Shift · **Status:** Draft (Vigneshwar to review)

Times both sorting algorithms on report rows of several sizes, for the efficiency comparison.

**Path / query parameters**

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `shiftId` | int | Yes | The shift's real report rows are the first data set |
| `sizes` | int list | No | Extra generated sizes, comma-separated. Default `100,1000,10000`. Each at most `20000` |

**Request body**

None

**Success response** – `200 OK`

An array of SortTiming: both algorithms for each data set, smallest first. (The numbers below are placeholders, not results.)

```json
[
  { "algorithm": "insertion", "itemCount": 12, "elapsedMicros": 0 },
  { "algorithm": "merge", "itemCount": 12, "elapsedMicros": 0 },
  { "algorithm": "insertion", "itemCount": 100, "elapsedMicros": 0 },
  { "algorithm": "merge", "itemCount": 100, "elapsedMicros": 0 }
]
```

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | A size is less than 1 or more than 20000 |
| 404 | `SHIFT_NOT_FOUND` | `shiftId` doesn't exist |

**Rules and notes**

- Generated rows use random quantities and revenue from a fixed seed, so every run times the same data.
- Both algorithms sort copies of the same list, by `quantity`.
- Each measurement runs once to warm up (discarded), then 5 times; `elapsedMicros` is the median.
- Runs on the request thread. Large sizes take a few seconds, so the frontend shows a loading state.

---

## 5. Java interface contracts

These are the Java types everyone codes against. Like the endpoints, each one moves from Draft to Agreed before anyone builds on it.

### 5.1 ListInterface

**Owner:** Tolu · **Used by:** everyone · **Status:** Agreed (array-based)

Package `com.bizkit.adt.list`. One generic list for checks on a table, courses on a check, items in a course, tables, the shift's paid checks, report rows and a menu node's children.

```java
import java.util.Iterator;

public interface ListInterface<T> extends Iterable<T> {
    void add(T entry);                 // add at the end
    void add(int position, T entry);   // insert at position; later entries shift up by one
    T remove(int position);            // remove and return; later entries shift down by one
    T get(int position);
    T set(int position, T entry);      // replace and return the old entry
    int size();
    boolean isEmpty();
    void clear();
    Iterator<T> iterator();            // our own iterator class, from Iterable
}
```

| Rule | Behaviour |
| --- | --- |
| Positions | Start at **0**, like Java arrays. `ORDER_ITEM.positionInCourse` stores the same number |
| Valid positions | `get`, `set` and `remove`: `0` to `size() - 1`. `add(position, entry)`: `0` to `size()`, where `size()` means the end |
| Out of range | Throws `IndexOutOfBoundsException`, a `java.lang` class, with the position and size in the message |
| `null` entries | Not allowed. `add` and `set` throw `IllegalArgumentException` |
| Empty list | `remove` and `get` on an empty list are out of range. `isEmpty()` is `true` and `size()` is `0` |
| Iterator | Visits entries from position 0 up, so the enhanced `for` loop works. Its `remove()` isn't supported and throws `UnsupportedOperationException` |
| Changing the list while iterating | Not supported. Collect the positions first, then change the list after the loop |

**Removing several items (multi-select move, merge, split).** Walk the list once and record the positions of the selected items; they come out in ascending order. Then remove them starting from the last recorded position and going down. Removing from the top keeps every lower position valid.

**Putting items back (Undo).** Re-insert the items at their original positions in ascending order. Each insert lands below every later one, so all positions end up exactly as before.

Example: a course holds `[Caesar, parm, carbonara, tiramisu]` and the parm and carbonara are selected. Recorded positions are 1 and 2. Remove 2 (carbonara), then 1 (parm), leaving `[Caesar, tiramisu]`. Undo inserts parm at 1, then carbonara at 2, giving back `[Caesar, parm, carbonara, tiramisu]`.

**Implementation: array-based (decided).** `get` and `set` are O(1), which the shift report's sorts need, and the timing comparison then measures the sorting algorithms rather than the list. Our lists are short, so shifting entries on insert and remove costs nothing noticeable. Vigneshwar to confirm, since his sorting code depends on it.

| | Array-based (chosen) | Linked |
| --- | --- | --- |
| `get` / `set` | O(1) | O(n), walks from the start |
| `add` / `remove` in the middle | O(n), shifts later entries | O(n) to reach the spot, then O(1) to relink |
| `add` at the end | O(1) usually, O(n) when the array grows | O(1) with a tail pointer |
| Sorting through `get` / `set` | Textbook speed | Much slower (insertion sort about O(n³)) |

### 5.2 Undo entries

**Owner:** Vigneshwar (format, drafted by Carolina) · **Input from:** Carolina, Tolu · **Status:** Draft (Vigneshwar to review)

Package `com.bizkit.undo`. Each undoable action pushes **one** `UndoAction`, however many items it changed. The Undo stack is a `LinkedStack<UndoAction>`.

```java
public enum UndoType { OPEN_CHECK, ADD_ITEM, REMOVE_ITEM, MOVE_COURSE, MOVE_TABLE, SPLIT }

public class ItemMove {
    int orderItemId;
    int fromCheckId;      // where the item was before the action
    int fromCourseId;
    int fromPosition;     // 0-based position in that course
    int toCheckId;        // where it went (same as fromCheckId for a course move)
    int toCourseId;
}

public class UndoAction {
    UndoType type;
    String label;           // the Snackbar text: "Merged 2 items"
    ItemMove[] moves;       // one per item changed; empty for OPEN_CHECK
    int createdCheckId;     // check this action created, or -1 (OPEN_CHECK, NEW_CHECK move, SPLIT)
    int closedCheckId;      // check this action closed, or -1 (source check emptied by a move)
    int[] touchedCheckIds;  // every check involved, for the paid-check rule
    OrderItem removedItem;  // REMOVE_ITEM only: full copy of the item, to put it back
}
```

Arrays, not `java.util` collections.

| Type | Pushed by | What Undo does |
| --- | --- | --- |
| `OPEN_CHECK` | Order service | Closes `createdCheckId` if it's still empty |
| `ADD_ITEM` | Order service | Removes the item from the position it was added at |
| `REMOVE_ITEM` | Order service | Re-inserts `removedItem` at `fromPosition` in `fromCourseId` |
| `MOVE_COURSE` | Floor service | Removes each item from its target course (highest position first), then re-inserts at `fromPosition` (ascending) |
| `MOVE_TABLE` | Floor service | Same as above across checks; reopens `closedCheckId`; closes `createdCheckId` |
| `SPLIT` | Floor service | Moves items back to `fromCheckId`; closes `createdCheckId` |

For `ADD_ITEM`, `fromCheckId`, `fromCourseId` and `fromPosition` hold where the item was **added**, and `toCheckId`/`toCourseId` are `-1`.

```java
public interface UndoManagerInterface {
    void push(UndoAction action);
    boolean canUndo();
    String peekLabel();       // null when empty
    UndoAction pop();         // throws IllegalStateException when empty
    void clear();             // called when the shift closes
}

public interface Undoable {   // implemented by OrderService and FloorService
    ChangeResult revert(UndoAction action);
}
```

**Flow for `POST /undo`.** The undo controller pops the top entry. If any check in `touchedCheckIds` is now `PAID`, the entry is discarded and the request fails with `CHECK_ALREADY_PAID`. Otherwise the entry goes to the service that owns its type (order service for the first three types, floor service for the rest), whose `revert` makes the change, saves it and returns the ChangeResult. Each owner writes the undo logic for their own actions; Vigneshwar owns the stack, the dispatch and the paid-check rule.

### 5.3 MenuTree methods

**Owner:** Carolina · **Used by:** Carolina (menu, order), Vigneshwar (shift report) · **Status:** Agreed by Carolina and Tolu; Vigneshwar to confirm `categoryTotals`

Package `com.bizkit.adt.tree`. A general tree of menu entries: categories hold categories or items, items hold add-ons. Each node keeps its children in a `ListInterface<MenuNode>`, so the tree reuses the team's List ADT.

```java
public enum EntryType { CATEGORY, ITEM, ADD_ON }

public class MenuNode {
    int entryId;
    String name;
    EntryType type;
    int priceCents;           // 0 for categories
    int defaultCourseId;      // -1 if none (categories, add-ons, drinks)
    boolean available;
    int displayOrder;
    ListInterface<MenuNode> children;   // in displayOrder
}

public interface MenuTreeInterface {
    MenuNode getRoot();
    void addChild(int parentEntryId, MenuNode child);   // used while loading; children kept in displayOrder
    MenuNode findById(int entryId);                     // recursive; null if missing
    MenuNode findByName(String name);                   // recursive, case-insensitive; first match in display order
    int priceWithAddOns(int itemEntryId, int[] addOnIds);
    int countItems();                                   // recursive
    ListInterface<CategoryTotal> categoryTotals(ListInterface<ReportRow> rows);
}
```

| Method | Rule |
| --- | --- |
| `addChild` | Throws `IllegalArgumentException` if the parent doesn't exist or the child's type can't go under it (an add-on under a category, an item under an add-on) |
| `findById`, `findByName` | Return `null` when nothing matches. Services turn `null` into `MENU_ENTRY_NOT_FOUND` |
| `priceWithAddOns` | Price of the item plus each chosen add-on, recursively, so an add-on's own add-ons would also count. Throws `IllegalArgumentException` if the entry isn't an item or an add-on isn't its child |
| `countItems` | Number of `ITEM` nodes in the whole tree |
| `categoryTotals` | Recursive: a category's total is the revenue of the items directly under it plus the totals of its sub-categories. Returns one `CategoryTotal` for every category that directly holds items, in display order, leaving out zero totals. Revenue for an item is found in `rows` by `menuItemId`; items not in `rows` count 0 |

`categoryTotals` searches `rows` once per item, so it is O(items × rows). Both are small for one shift, and this keeps the method on our own List instead of a hash map.

### 5.4 Decisions from the contracts meeting

| # | Question | Decision | Status |
| --- | --- | --- | --- |
| 1 | `java.util.Iterator` | `adt/list/` imports `java.util.Iterator` so the enhanced `for` loop works. It's an interface, not a collection; the list and iterator class are our own. | Agreed; Tolu confirming with the TA |
| 2 | Who made the change? | Actions on a check use the check's server. Opening a check and closing the shift send the `employeeId` shown in the top bar. | Agreed |
| 3 | Undo after a payment | Undo never changes a paid check. If the top entry touches a now-paid check, Undo discards it and returns `CHECK_ALREADY_PAID`, so the stack doesn't get stuck. | Agreed by Carolina and Tolu; Vigneshwar to confirm |
| 4 | Refunds | A refund is not an undo: it moves money back and needs its own record. Out of scope for this project; listed as future work. Design if added later: a refund is a PAYMENT row with `transactionKind` = refund and `refundOfPaymentId` pointing to the original charge, plus a REFUND subtype for the reason and the approving MANAGER. | Agreed |
| 5 | List responses | `GET` endpoints that return a list return a plain JSON array. | Agreed |
| 6 | List implementation | Array-based (see 5.1). | Agreed; Vigneshwar to confirm |