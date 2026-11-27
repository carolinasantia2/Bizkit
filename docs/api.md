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
| Money | **Integer cents**, and the field name ends in `Cents`: `1350` = $13.50 (`unitPriceCents`, `totalCents`). The frontend only formats it for display. |
| Dates and times | ISO 8601 strings: `"2026-12-02T18:30:00"` |
| Status values | Uppercase words, never the single letters stored in the database: `"OPEN"`, `"PAID"`, `"CLOSED"`, `"HELD"`, `"SENT"` |
| Empty lists | Always `[]`, never `null` |
| Optional fields | Present with `null` when there is no value |
| Who computes | The backend computes all prices, totals, sorting and grouping (that's where our ADTs and algorithms live). The frontend never sums or sorts data itself. |
| Changes | Any request that changes data returns the `ChangeResult` shape (section 2) so the frontend can redraw without another request. |

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
| `ITEM_NOT_FOUND` | 404 | |
| `MENU_ENTRY_NOT_FOUND` | 404 | |
| `CHECK_ALREADY_PAID` | 409 | |
| `NOTHING_TO_UNDO` | 409 | The undo stack is empty |
| `SHIFT_ALREADY_CLOSED` | 409 | |
| `CHECK_CLOSED` | 409 | The check was emptied by a move and closed, so it can't be changed |

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
| `removedCheckIds` | int[] | Checks that no longer exist (emptied by a move) |
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
| GET | `/menu` | Carolina | Take Order | Draft |
| GET | `/menu/items/{entryId}/price` | Carolina | Take Order | Draft |
| POST | `/checks` | Carolina | Take Order | Draft |
| POST | `/checks/{checkId}/items` | Carolina | Take Order | Draft |
| DELETE | `/checks/{checkId}/items/{orderItemId}` | Carolina | Take Order | Draft |
| POST | `/checks/{checkId}/send` | Carolina | Take Order | Draft |
| GET | `/tables` | Tolu | Tables | Draft |
| GET | `/tables/{tableId}/checks` | Tolu | Tables, Take Order | Draft |
| POST | `/checks/{checkId}/items/move-course` | Tolu | Tables | Draft |
| POST | `/items/move-table` | Tolu | Tables | Draft |
| POST | `/checks/{checkId}/split` | Tolu | Tables | Draft |
| POST | `/checks/{checkId}/payments` | Tolu | Tables | Draft |
| GET | `/undo` | Vigneshwar | All (top bar) | Draft |
| POST | `/undo` | Vigneshwar | All (top bar) | Draft |
| GET | `/shifts/current/summary` | Vigneshwar | Close Shift | Draft |
| POST | `/shifts/current/close` | Vigneshwar | Close Shift | Draft |
| GET | `/shifts/{shiftId}/report` | Vigneshwar | Close Shift | Draft |
| GET | `/shifts/{shiftId}/sort-timing` | Vigneshwar | Close Shift | Draft |

---

## 4. Endpoints

Copy this template for each endpoint and fill in every part. Delete nothing; write "None" where a part doesn't apply.

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

### Reference example: POST /items/move-table

**Owner:** Tolu · **Called by:** Tables · **Status:** Draft

Moves selected items to another table, following the auto-merge rules.

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

`targetCheckId` is `null` on the first call. It's set only when the user picks a check in the "several checks" dialog, or `-1` for "a new separate check".

**Success response** – `200 OK`

ChangeResult plus two fields:

```json
{
  "result": "MERGED",
  "options": [],
  "checks": [ { "checkId": 7, "tableNumber": 4, "...": "Check shape" } ],
  "removedCheckIds": [],
  "undo": { "canUndo": true, "label": "Merged 2 items" },
  "message": "Merged 2 items into Table 4's check"
}
```

| `result` | Meaning |
| --- | --- |
| `NEW_CHECK` | Target table had no checks; the items became a new check there |
| `MERGED` | Target had one check (or the user chose one); items merged into it |
| `CHOOSE_CHECK` | Target has several checks and no `targetCheckId` was sent. **Nothing moved.** `options` lists the candidate checks; the frontend shows the dialog (wireframe 2.4) and calls again with the chosen `targetCheckId`. |

**Errors**

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | `orderItemIds` is empty, or the target is the items' current table |
| 404 | `TABLE_NOT_FOUND` | `targetTableId` doesn't exist |
| 404 | `ITEM_NOT_FOUND` | Any ID in `orderItemIds` doesn't exist |

**Rules and notes**

- Moved items keep their course.
- A source check left empty is removed and its ID returned in `removedCheckIds`.
- The whole move is one Undo entry, pushed to the Stack ADT.
- Items are removed from the source List from the highest position down, so positions don't shift.

---

<!-- Add the remaining endpoints below, in the order of the index. -->

<!-- Floor endpoints (Tolu). The menu and order endpoints go above this block. -->

### GET /tables

**Owner:** Tolu · **Called by:** Tables · **Status:** Draft

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

**Owner:** Tolu · **Called by:** Tables, Take Order · **Status:** Draft

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
- Items without a default course (drinks) still sit in a course; the order endpoints decide which one when the item is added.

---

### POST /checks/{checkId}/items/move-course

**Owner:** Tolu · **Called by:** Tables · **Status:** Draft

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

**Owner:** Tolu · **Called by:** Tables · **Status:** Draft

Moves selected items to another table, following the auto-merge rules (coworker issue 2). This is the reference example above, completed.

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

**Owner:** Tolu · **Called by:** Tables · **Status:** Draft

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

**Owner:** Tolu · **Called by:** Tables · **Status:** Draft

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
- Payments are not undoable, so `undo` is returned unchanged.

---

<!-- End of floor endpoints. -->

## 5. Java interface contracts

These are the Java types everyone codes against. Like the endpoints, each one moves from Draft to Agreed before anyone builds on it.

### 5.1 ListInterface

**Owner:** Tolu · **Used by:** everyone · **Status:** Draft

Package `com.bizkit.adt.list`. One generic list for checks on a table, courses on a check, items in a course, tables, the shift's paid checks and report rows.

```java
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

**Implementation choice: array-based or linked?** To agree at the meeting.

| | Array-based (resizable array) | Linked (chain of nodes) |
| --- | --- | --- |
| `get` / `set` | O(1) | O(n), walks from the start |
| `add` / `remove` in the middle | O(n), shifts later entries | O(n) to reach the spot, then O(1) to relink |
| `add` at the end | O(1) usually, O(n) when the array grows | O(1) with a tail pointer |
| Sorting through `get` / `set` | Textbook speed, so the timing comparison is fair | Much slower (insertion sort about O(n³)), so the timing measures the list, not the sort |

Proposal: **array-based.** Our lists are short, so shifting costs nothing noticeable, and the shift report's sorts and their timing comparison need fast `get` and `set`. Vigneshwar's sorting code depends on this choice, so he should agree to it.

### 5.2 Undo entries from the floor service

**Owner:** Vigneshwar (format) · **Input from:** Tolu · **Status:** Draft

Vigneshwar defines the Undo entry format. This is what the floor service needs each entry to hold so that a move, merge or split can be reversed exactly:

| Action | What the entry must record |
| --- | --- |
| Course move | For each moved item: `orderItemId`, `checkId`, original `courseId` and original position |
| Move to table (MERGED or NEW_CHECK) | For each moved item: `orderItemId`, source `checkId`, `courseId` and original position, plus target `checkId`. Also: the new check's ID if one was created, and the source check's ID if it was closed |
| Split | For each moved item: `orderItemId`, original `checkId`, `courseId` and original position, plus the new check's ID |

Each action pushes **one** entry, however many items it moved. The label is the Snackbar text: `"Moved 2 items to Apps"`, `"Merged 2 items"`, `"Split 1 item"`.

### 5.3 MenuTree methods for the shift report

**Owner:** Carolina · **Status:** To be added

### 5.4 Open questions for the contracts meeting

1. **`java.util.Iterator` (FYI).** The enhanced `for` loop only works if `iterator()` returns a `java.util.Iterator`, so `adt/list/` imports that one interface. It's an interface, not a collection; the list and the iterator class are our own code. A home-made iterator interface would rule out the enhanced `for` loop everywhere, so we're keeping this import and will mention it to the TA.
2. **Who made the change?** ITEM_TRANSFER and PAYMENT need an employee ID, but the app has no login. Proposal: the backend uses the check's server for moves, splits and payments.
3. **Undo after a payment.** If a check is paid and the next Undo would change it (for example, undoing the merge that filled it), the Undo manager should refuse with `CHECK_ALREADY_PAID` instead of changing a paid check.
4. **List responses.** `GET` endpoints that return a list (`/tables`, `/tables/{tableId}/checks`) return a plain JSON array, not an object around it. Confirm everyone uses the same style.
