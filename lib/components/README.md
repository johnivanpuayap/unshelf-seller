# Seller Components

Reusable widgets for the Unshelf seller Flutter app. These widgets are **seller-specific** — per the uniqueness rule (memory `[[unshelf-buyer-seller-uniqueness]]`), the buyer app has its own components. Only the auth flow is visually shared between apps (see `brand-kit/docs/crucible/auth-screens.md` in the submodule).

All components consume the brand theme via `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`. None hardcode colors or fonts.

Card surfaces use the canonical Soft Editorial pattern: `surfaceContainerHighest` fill, 14px radius, two-layer shadow (1px hairline + 8px ambient with the canonical `0xFF1F2A20` shadow tint).

> **Note on `chat_screen.dart`:** despite living in `lib/components/`, this is a full-screen view (it owns its own `Scaffold` + inline `AppBar`). The misfiling predates the rebrand; relocating it is out of scope for Phase 5 and is tracked for the buyer-rebrand follow-ups.

## Catalog

### Chart

A line chart for time-series analytics screens.

**File:** `lib/components/chart.dart`

**Props:**
- `dataMap` (`Map<DateTime, dynamic>`, required) — time-indexed values; keys plot along the x-axis, values along the y-axis
- `maxXValue` (`double`, required) — count of x-axis steps for axis labelling and tick sizing
- `maxYValue` (`double`, required) — y-axis upper bound; used to space horizontal gridlines

**Used by:**
- `lib/views/product_analytics_view.dart`
- `lib/views/store_analytics_view.dart`

**Example:**
```dart
Chart(dataMap: dailySales, maxXValue: 7, maxYValue: 5000)
```

---

### ChatBubble

A single chat message bubble with side-aware corner radii.

**File:** `lib/components/chat_bubble.dart`

**Props:**
- `text` (`String`, required) — message body
- `isOwn` (`bool`, required) — `true` aligns right with `cs.primary`; `false` aligns left with `cs.surfaceContainerHighest`
- `timestamp` (`DateTime?`, optional) — renders a small caption below the bubble
- `isRead` (`bool?`, optional) — drives the read-receipt glyph for outgoing messages

**Used by:**
- `lib/components/chat_screen.dart`

**Example:**
```dart
ChatBubble(text: 'On my way!', isOwn: true, timestamp: DateTime.now())
```

---

### ChatScreen

Single-conversation surface between the seller and one buyer. Streams messages from `IChatService` and renders them as `ChatBubble`s.

**File:** `lib/components/chat_screen.dart` (full-screen view; misfiled under components — see note above)

**Props:**
- `receiverName` (`String`, required) — peer display name in the app bar
- `receiverUserID` (`String`, required) — Firestore uid used to stream the message thread
- `receiverAvatarUrl` (`String?`, optional) — avatar URL; falls back to an initial-only avatar

**Used by:**
- `lib/views/chats_view.dart`

**Example:**
```dart
ChatScreen(receiverName: 'Anna', receiverUserID: 'u_123')
```

---

### EmptyState

Centered illustration + headline + optional action, shown when a list or page has no content.

**File:** `lib/components/empty_state.dart`

**Props:**
- `icon` (`IconData`, required) — large muted glyph
- `title` (`String`, required) — primary headline (`titleMedium`)
- `subtitle` (`String?`, optional) — supporting copy
- `actionLabel` (`String?`, optional) — outlined button label; ignored unless `onAction` is also set
- `onAction` (`VoidCallback?`, optional) — outlined button callback

**Used by:**
- `lib/views/balance_overview_view.dart`
- `lib/views/batch_history_view.dart`
- `lib/views/bundle_details_view.dart`
- `lib/views/chats_view.dart`
- `lib/views/dashboard_view.dart`
- `lib/views/inventory_view.dart`
- `lib/views/listings_view.dart`
- `lib/views/notifications_view.dart`
- `lib/views/order_details_view.dart`
- `lib/views/order_history_details_view.dart`
- `lib/views/order_history_view.dart`
- `lib/views/orders_view.dart`
- `lib/views/product_details_view.dart`
- `lib/views/restock_details_view.dart`
- `lib/views/restock_selection_view.dart`
- `lib/views/select_products_view.dart`
- `lib/views/store_analytics_view.dart`

**Example:**
```dart
EmptyState(
  icon: Icons.inventory_2_outlined,
  title: 'No products yet',
  subtitle: 'Tap the + button to add your first product',
  actionLabel: 'Add product',
  onAction: () => Navigator.push(...),
)
```

---

### FieldLabel

Field label rendered above text inputs on Quality-Bar form screens.

**File:** `lib/components/field_label.dart`

**Props:**
- `text` (`String`, required) — label copy
- `color` (`Color`, required) — text color; pass `cs.onSurface` on `surfaceContainerHighest` cards, `cs.onBackground` on auth screens over `cs.surface`

**Used by:**
- `lib/authentication/views/forgot_password_view.dart`
- `lib/authentication/views/login_view.dart`
- `lib/authentication/views/register_view.dart`
- `lib/authentication/views/reset_password_view.dart`
- `lib/views/add_batch_view.dart`
- `lib/views/add_bundle_view.dart`
- `lib/views/add_product_view.dart`
- `lib/views/edit_batch_view.dart`
- `lib/views/edit_bundle_view.dart`
- `lib/views/edit_product_view.dart`
- `lib/views/edit_store_profile_view.dart`
- `lib/views/edit_user_profile_view.dart`
- `lib/views/report_view.dart`
- `lib/views/restock_details_view.dart`
- `lib/views/withdraw_request_view.dart`

**Example:**
```dart
FieldLabel('Email', color: cs.onSurface)
```

---

### ImageWithDelete

Hoverable thumbnail with a centered delete icon overlay; used in image-gallery editors.

**File:** `lib/components/image_delete.dart`

**Props:**
- `imageData` (`Uint8List`, required) — in-memory image bytes (uploads in progress)
- `onDelete` (`VoidCallback`, required) — invoked when the tile or the delete icon is tapped
- `width` (`double`, optional, default `70.0`) — tile width
- `height` (`double`, optional, default `70.0`) — tile height
- `margin` (`EdgeInsets`, optional, default `EdgeInsets.only(right: 2)`) — outer margin between tiles

**Used by:**
- `lib/views/add_bundle_view.dart`
- `lib/views/edit_bundle_view.dart`

**Example:**
```dart
ImageWithDelete(imageData: bytes, onDelete: () => removeImage(index))
```

---

### OrderCard

A compact card representing a single order; used in lists and the dashboard recent-orders section.

**File:** `lib/components/order_card.dart`

**Props:**
- `orderId` (`String`, required) — short order id rendered as the eyebrow
- `buyerName` (`String`, required) — primary line
- `status` (`String`, required) — status string passed through to a nested `StatusBadge`
- `totalPrice` (`double`, required) — formatted as `₱x.xx`
- `createdAt` (`DateTime`, required) — formatted as `MMM d, y`
- `itemCount` (`int`, required) — number of line items
- `onTap` (`VoidCallback?`, optional) — full-card tap callback

**Used by:**
- `lib/views/dashboard_view.dart`
- `lib/views/orders_view.dart`

**Example:**
```dart
OrderCard(
  orderId: order.id,
  buyerName: order.buyerName,
  status: order.status,
  totalPrice: order.total,
  createdAt: order.createdAt,
  itemCount: order.items.length,
  onTap: () => Navigator.push(...),
)
```

---

### ProductCard

A card representing a product or bundle listing. Soft Editorial card surface with a category chip and an options menu.

**File:** `lib/components/product_card.dart`

**Props:**
- `name` (`String`, required) — product name
- `imageUrl` (`String?`, optional) — remote image; falls back to a placeholder
- `category` (`String?`, optional) — small category chip rendered over the image
- `batchCount` (`int?`, optional) — caption text beneath the name
- `onTap` (`VoidCallback?`, optional) — full-card tap callback
- `onEdit` (`VoidCallback?`, optional) — surfaced from the kebab menu
- `onDelete` (`VoidCallback?`, optional) — surfaced from the kebab menu

**Used by:**
- `lib/views/listings_view.dart`
- `lib/views/restock_details_view.dart`

**Example:**
```dart
ProductCard(
  name: product.name,
  imageUrl: product.imageUrl,
  category: product.category,
  batchCount: product.batches.length,
  onTap: () => Navigator.push(...),
)
```

---

### SectionHeader

A section title row with an optional "See all" / action text button. Title uses DM Serif Display (`titleLarge`) for the editorial feel.

**File:** `lib/components/section_header.dart`

**Props:**
- `title` (`String`, required) — section heading
- `actionLabel` (`String?`, optional) — trailing text-button label; ignored unless `onAction` is set
- `onAction` (`VoidCallback?`, optional) — trailing text-button callback

**Used by:**
- `lib/views/balance_overview_view.dart`
- `lib/views/dashboard_view.dart`
- `lib/views/product_analytics_view.dart`
- `lib/views/product_details_view.dart`
- `lib/views/store_analytics_view.dart`

**Example:**
```dart
SectionHeader(title: 'Recent orders', actionLabel: 'See all', onAction: () => ...)
```

---

### SettingsTile

A Quality-Bar settings row used inside a grouped settings card. Leading icon in a primary-tinted rounded square, title, optional subtitle, optional trailing widget (defaults to a chevron).

**File:** `lib/components/settings_tile.dart`

**Props:**
- `icon` (`IconData`, required) — leading glyph
- `title` (`String`, required) — primary line
- `subtitle` (`String?`, optional) — secondary line
- `trailing` (`Widget?`, optional) — e.g. a `Switch`; defaults to a chevron
- `onTap` (`VoidCallback?`, optional) — row tap callback
- `iconColor` (`Color?`, optional) — overrides the leading-icon tint; useful for destructive rows (`cs.error`)
- `titleColor` (`Color?`, optional) — overrides the title color; mirrors `iconColor` for destructive rows

**Used by:**
- `lib/views/settings_view.dart`

**Example:**
```dart
SettingsTile(
  icon: Icons.notifications_outlined,
  title: 'Notifications',
  subtitle: 'Email and push',
  onTap: () => Navigator.push(...),
)
```

---

### StatCard

A KPI metric card. Soft Editorial card surface containing an icon, a label, and a numeric value.

**File:** `lib/components/stat_card.dart`

**Props:**
- `label` (`String`, required) — small caption
- `value` (`String`, required) — formatted metric value
- `icon` (`IconData`, required) — leading icon shown in a tinted rounded square
- `iconColor` (`Color?`, optional) — overrides the default `cs.primary` tint

**Used by:**
- `lib/views/balance_overview_view.dart`
- `lib/views/bundle_details_view.dart`
- `lib/views/dashboard_view.dart`
- `lib/views/product_analytics_view.dart`
- `lib/views/product_details_view.dart`
- `lib/views/store_analytics_view.dart`
- `lib/views/store_view.dart`

**Example:**
```dart
StatCard(label: 'Today\'s sales', value: '₱1,240', icon: Icons.attach_money)
```

---

### StatusBadge

A compact, pill-shaped badge that maps an order/payment/product status string to a `colorScheme` role.

**File:** `lib/components/status_badge.dart`

Mapping (driven by `core/constants/status_constants.dart`):
- Pending / Processing → `tertiary`
- Ready / Completed / Paid → `primary`
- Cancelled / Unpaid → `error`
- Low stock / Out of stock → `error`

**Props:**
- `status` (`String`, required) — status string from `StatusConstants`

**Used by:**
- `lib/components/order_card.dart`
- `lib/views/order_details_view.dart`
- `lib/views/order_history_details_view.dart`
- `lib/views/order_history_view.dart`

**Example:**
```dart
StatusBadge(status: StatusConstants.ready)
```
