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
