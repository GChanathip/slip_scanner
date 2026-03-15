# Test Plan: Custom Categories + Learning Pipeline

**Task**: CHG-59
**Feature**: User-defined categories + learning from corrections
**Date**: 2026-03-15
**QA Engineer**: QA Engineer Agent

---

## Overview

This document describes the comprehensive test plan for the custom categories feature, including user-defined category management and AI learning from corrections. The feature allows users to:

1. Create and manage custom expense categories (max 20)
2. Set categorization rules based on recipient patterns
3. Learn from user corrections to auto-categorize future transactions
4. Maintain existing 14 built-in categories as read-only

---

## Test Structure

The test plan is organized into **7 test files** with **83 total tests**:

| # | File | Tests | Coverage |
|---|------|-------|----------|
| 1 | `category_service_test.dart` | 17 | CategoryService CRUD, merge, rules, validation |
| 2 | `extraction_service_custom_categories_test.dart` | 7 | ExtractionService with rule override |
| 3 | `category_management_screen_test.dart` | 10 | UI for category management |
| 4 | `category_edit_sheet_test.dart` | 15 | UI for category creation/editing |
| 5 | `category_learning_integration_test.dart` | 8 | End-to-end learning flow |
| 6 | `category_edge_cases_test.dart` | 13 | Boundary conditions and edge cases |
| 7 | `category_regression_test.dart` | 13 | Regression protection for existing features |

**Total**: 83 tests

---

## Detailed Test Coverage

### 1. CategoryService Tests (17 tests)

**Location**: `test/category_service_test.dart`

Tests the core service for custom category management.

#### CRUD Operations (7 tests)

- **create**: Adds new custom category with icon and color
- **create duplicate rejection**: Rejects duplicate names (case-insensitive)
- **create 20-limit**: Enforces maximum 20 custom categories
- **getAll**: Retrieves all custom categories
- **update**: Renames category with cascade to slips
- **update cascade**: Updates `payment_slips.category` and `category_rules`
- **delete**: Cascades to 'other' category and removes rules

#### Merge Operations (3 tests)

- **merge to custom**: Moves slips and rules from source to target category
- **merge to built-in**: Allows merging to built-in category names
- **merge deletes source**: Removes source category after merge

#### Category Rules (5 tests)

- **findRule null**: Returns null for unknown recipient
- **findRule match**: Returns rule for normalized recipient
- **upsertRule create/update**: Creates or updates rule
- **getAllRules**: Retrieves all rules
- **deleteRule**: Removes specific rule

#### Normalization (2 tests)

- **normalizeRecipient**: Lowercase, trim, collapse whitespace
- **normalizeRecipient empty**: Handles empty/whitespace-only strings

---

### 2. ExtractionService Tests (7 tests)

**Location**: `test/extraction_service_custom_categories_test.dart`

Tests LLM extraction with rule lookup and category validation.

#### Rule Override (5 tests)

- **rule exists**: LLM category overridden, `categorySource = 'rule'`
- **no rule**: LLM category used, `categorySource = 'ai'`
- **rule for built-in**: Rule pointing to built-in category accepted
- **rule for custom**: Rule pointing to custom category accepted
- **normalized match**: Lookups work with whitespace/casing variations

#### Validation (2 tests)

- **custom category valid**: LLM returns custom category name → accepted
- **unknown category fallback**: Invalid category → defaults to 'other'

---

### 3. Widget Tests: CategoryManagementScreen (10 tests)

**Location**: `test/category_management_screen_test.dart`

Tests the settings screen for managing custom categories.

- **Built-in list**: Displays 14 built-in categories (read-only)
- **Custom list**: Displays custom categories (editable)
- **Empty state**: Shows message when no custom categories
- **20-limit indicator**: Disables add button, shows warning at limit
- **Edit action**: Opens CategoryEditSheet in edit mode
- **Delete action**: Shows confirmation dialog before delete
- **Merge action**: Shows target picker (custom + built-in options)
- **Slip count**: Displays transaction count for each category
- **Add button**: Navigates to create mode
- **After delete**: Category removed from list and restored count

---

### 4. Widget Tests: CategoryEditSheet (15 tests)

**Location**: `test/category_edit_sheet_test.dart`

Tests the modal bottom sheet for creating/editing custom categories.

#### Form and UI (6 tests)

- **Create mode**: Shows empty form with default icon/color
- **Edit mode**: Prefills form with existing category data
- **Live preview**: Updates preview as user changes name/icon/color
- **Icon grid**: Shows 16 icons in 4x4 grid
- **Color palette**: Shows 8 color swatches
- **Preview rendering**: Displays selected icon and color in preview

#### Validation (5 tests)

- **Name required**: Rejects empty name
- **Name length**: Enforces 1-30 character limit
- **Duplicate rejection** (create): Rejects duplicate names
- **Duplicate rejection** (edit): Case-insensitive duplicate check
- **Conflicting names**: Rejects rename to built-in category name

#### Actions (4 tests)

- **Save (create)**: Calls CategoryService.create and closes
- **Save (edit)**: Calls CategoryService.update and closes
- **Cancel**: Closes without saving
- **Changes tracked**: Enables/disables save button based on changes

---

### 5. Integration Tests: Learning Pipeline (8 tests)

**Location**: `test/category_learning_integration_test.dart`

Tests the full correction → rule → re-extraction flow.

#### Scenario: Scan → Correct → Learn

1. **Initial extraction**: Grab slip extracted with AI category 'shopping' (incorrect)
2. **User correction**: User changes to 'transport'
3. **Rule creation**: System creates rule: Grab → transport
4. **New slip**: Another Grab transaction arrives
5. **Rule applied**: LLM categorizes as 'food', but rule overrides → 'transport'
6. **Verification**: Slip saved with `categorySource = 'rule'`

#### Test Cases (8 tests)

- **Full flow**: End-to-end correction to rule application
- **Correction validation**: Rule created, slip updated
- **Rule override**: AI category replaced by rule
- **Custom category**: Rules can point to custom categories
- **Normalization**: Rule lookups work with whitespace/casing
- **Rule updated on merge**: Merge cascades rule to new target
- **Rule deleted on category delete**: Deleting category removes its rules
- **No rule for empty recipient**: Empty recipientName → no rule created
- **Same category selected**: No rule if category unchanged

---

### 6. Edge Case Tests (13 tests)

**Location**: `test/category_edge_cases_test.dart`

Tests boundary conditions and unusual scenarios.

#### Category Operations (8 tests)

- **Merge last remaining**: Merge the only custom category
- **Delete empty category**: Delete category with 0 slips
- **Exactly 30-char name**: Maximum length boundary
- **31-char name rejected**: Over limit rejection
- **Rename conflicting**: Reject rename to existing name
- **20-category limit boundary**: Exactly 20 allowed, 21st rejected
- **Whitespace normalization**: Leading/trailing whitespace trimmed
- **Unicode support**: Thai and special characters accepted

#### Undo and Cleanup (3 tests)

- **Undo after navigate away**: SnackBar timeout doesn't persist undo
- **Budget cleanup on delete**: Removes budget entries
- **Cascade on delete**: All slips reassigned to 'other'

#### Complex Merges (2 tests)

- **Merge with multiple rules**: Rules from both categories handled
- **Cascade on rename**: Updates slips and rules atomically

---

### 7. Regression Tests (13 tests)

**Location**: `test/category_regression_test.dart`

Ensures existing functionality is not broken.

#### Built-in Categories (3 tests)

- **14 categories valid**: All built-in categories remain in system
- **Built-in behavior unchanged**: Icons, colors, ordering preserved
- **Built-in read-only**: Cannot rename/delete built-in categories

#### Data Migration (3 tests)

- **NULL categorySource**: Pre-v7 slips with NULL preserved
- **Migration preserves data**: All fields survive v6→v7 migration
- **Bulk operations unchanged**: Batch insert/update/delete work

#### Existing Features (7 tests)

- **Category filtering**: Filter by category in reports/dashboards
- **Budget tracking**: Budget entries include custom categories
- **OCR extraction**: OCR fields (sender, reference, account) unchanged
- **LLM queue**: Extraction processing continues normally
- **RAG indexing**: RAG indexing works with new field
- **UI display**: Categories display correctly in lists and cards
- **Recurring transactions**: Recurring field interactions tested

---

## Acceptance Criteria

### Phase Dependencies

Tests are written for the expected implementation from CHG-52's architecture plan:

**Phase 1** (Foundation):
- ✅ DB migration v6→v7 (new tables, column)
- ✅ CategoryService with full CRUD and rules
- ✅ Models: CustomCategory, CategoryRule, updated PaymentSlip
- ✅ Category registry centralization

**Phase 2** (Integration):
- ✅ ExtractionService rule lookup and override
- ✅ Riverpod providers for categories
- ✅ UI screens: CategoryManagementScreen, CategoryEditSheet

**Phase 3** (Learning UX):
- ✅ SlipDetailScreen [AI]/[You]/[Rule] badges
- ✅ Learning SnackBar with undo
- ✅ ManualEntryBottomSheet integration

**Phase 4** (QA — Current):
- ✅ Test plan created (THIS TASK)
- ⏳ Execute tests: `flutter test` must pass 100%
- ⏳ Verify coverage meets requirements
- ⏳ Confirm no regressions

### Passing Criteria

1. **All 83 tests pass**: `flutter test` green for all test files
2. **No regressions**: All existing tests continue passing
3. **Code coverage**: >80% coverage for new code paths
4. **Integration verified**: Full learning flow works end-to-end
5. **Edge cases handled**: No crashes or unexpected behavior

---

## Running the Tests

### Prerequisites

- Flutter 3.38.x+ with Dart 3.10.4+
- `sqflite_common_ffi` dev dependency (for test DB)
- All Phase 1-3 implementation complete

### Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/category_service_test.dart

# Run with coverage
flutter test --coverage
lcov --list coverage/lcov.info

# Run tests matching pattern
flutter test --name "CategoryService CRUD"

# Run tests in debug mode (verbose)
flutter test -v

# Run tests and stop on first failure
flutter test --bail
```

### Expected Output

```
✓ All 83 tests should pass
✓ No test timeouts
✓ No unhandled exceptions
✓ Code coverage >80%
```

---

## Implementation Notes for Testing

### Mocking Requirements

Some tests use mocks or stub implementations:

1. **DatabaseService**: Tests assume in-memory SQLite (sqflite_ffi)
2. **ExtractionService**: Tests use mock LLM responses
3. **BudgetService**: Integration mocked or skipped
4. **Platform channel**: Not tested (platform-level)

### Test Database

Tests create an isolated in-memory SQLite database via sqflite_ffi:

```dart
sqfliteFfiInit();
databaseFactory = databaseFactoryFfi;
```

Each test group should:
- Initialize fresh DB in `setUp()`
- Clean up in `tearDown()`
- Not share state between tests

### Async Handling

Tests use `WidgetTester.pumpAndSettle()` for async operations:

```dart
await tester.tap(find.text('Save'));
await tester.pumpAndSettle(); // Wait for animations, futures
```

---

## Known Limitations

1. **Widget tests**: Patrol integration tests (native interaction) excluded from unit/widget test suite
2. **Platform tests**: iOS XCTests not included (native OCR/regex tested separately)
3. **Performance tests**: Load testing (1000+ categories) not included
4. **Concurrency**: Tests assume single-threaded execution

---

## Test Maintenance

### When to Update Tests

- New fields added to CustomCategory/CategoryRule
- New validation rules added to CategoryService
- Changes to rule lookup/normalization logic
- UI changes to category screens
- Database schema changes

### Before Merging

1. Run `flutter test` locally
2. Verify no test skips or timeouts
3. Check code coverage remains >80%
4. Confirm no new warnings in `flutter analyze`

---

## References

- **Architecture Plan**: CHG-52 `<plan>` section 8
- **Feature Task**: CHG-52 (parent)
- **Test Plan Task**: CHG-59 (this task)
- **Database Schema**: v6→v7 migration
- **Riverpod Docs**: State management pattern
- **Flutter Test Docs**: Widget/unit testing

---

## Sign-Off

**QA Engineer**: Created by QA Engineer Agent
**Status**: ✅ Test plan complete, awaiting Phase 1-3 implementation
**Next Step**: Execute tests when implementation is available
