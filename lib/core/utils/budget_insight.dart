import '../utils/formatters.dart';

/// Generates stable, state-aware motivational messages for the budget card.
///
/// "Stable" means: the selected message within a tier stays the same all day
/// and only rotates quietly to the next one tomorrow. It never jumps around
/// on each widget rebuild.
class BudgetInsight {
  BudgetInsight._();

  // ─────────────────────────────────────────────────────────────────────────
  // Today view insight
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a one-line insight for the Today budget view.
  ///
  /// [progress]  fraction spent (0.0 = nothing, 1.0 = exactly at target,
  ///             >1.0 = over)
  /// [remaining] absolute remaining amount (negative when over)
  /// [currency]  currency symbol
  static String todayInsight({
    required double progress,
    required double remaining,
    required String currency,
  }) {
    final pct = progress * 100;

    // ── Nothing spent yet (exactly 0%) ────────────────────────────────────
    if (progress == 0) {
      return "The budget is all yours — go spend it wisely! 😎";
    }

    if (progress > 1.0) {
      // ── Over target ──────────────────────────────────────────────────────
      final overAmount = Formatters.money(remaining.abs(), currency);
      final messages = [
        'Oops 😅 $overAmount over today.',
        'Welp, we crossed the line 😬',
        'A little over today. Tomorrow is a new start.',
        "Well... that escalated 😂 $overAmount over.",
        'It happens. Fresh start tomorrow 💪',
      ];
      return _pick(messages);
    }

    if (pct >= 80) {
      // ── Getting close (80–100%) ───────────────────────────────────────────
      final leftAmount = Formatters.money(remaining, currency);
      final messages = [
        'Easy there 😅 Only $leftAmount left today.',
        "Almost at today's limit 👀",
        'Careful, you\'re getting close.',
        "A little left in the tank 💰 $leftAmount.",
        'Watch out — nearly there.',
      ];
      return _pick(messages);
    }

    if (pct >= 50) {
      // ── On track (50–80%) ────────────────────────────────────────────────
      final messages = [
        "Still on track 👍",
        "Good work! Keep it up.",
        "Looking pretty good 👌",
        "Halfway there, keep it steady.",
        "Solid progress today 💪",
      ];
      return _pick(messages);
    }

    // ── Very comfortable (under 50%) ───────────────────────────────────────
    final messages = [
      "Looking good! 👌",
      "You're doing great today!",
      "Nice control today 🔥",
      "Your wallet is breathing easy 😎",
      "Great start to the day!",
    ];
    return _pick(messages);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // This Month view insight
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a one-line insight for the This Month budget view.
  ///
  /// [progress]   fraction of monthly budget spent (may exceed 1.0)
  /// [remaining]  amount remaining (negative when over)
  /// [daysLeft]   calendar days left in the current month
  /// [currency]   currency symbol
  /// [hasBudget]  false when the user hasn't set a monthly budget yet
  static String monthInsight({
    required double progress,
    required double remaining,
    required int daysLeft,
    required String currency,
    required bool hasBudget,
  }) {
    if (!hasBudget) {
      return 'Set a monthly budget to track your progress 📋';
    }

    final pct = progress * 100;

    if (progress > 1.0) {
      // ── Over monthly budget ───────────────────────────────────────────────
      final overAmount = Formatters.money(remaining.abs(), currency);
      final messages = [
        'Over budget by $overAmount 😬',
        'Exceeded this month\'s budget — $overAmount over.',
        "We went a bit over 😅 $overAmount past budget.",
        'Budget crossed. Time to cut back.',
      ];
      return _pick(messages);
    }

    // ── Under monthly budget: show actionable daily-rate insight ─────────
    if (daysLeft <= 0) {
      // Last day of the month
      return "Last day of the month! Finish strong 💪";
    }

    if (daysLeft == 1) {
      return "Last day tomorrow — make it count!";
    }

    // Core insight: per-day allowance for the rest of the month.
    final perDay = remaining > 0 ? remaining / daysLeft : 0.0;
    final perDayStr = Formatters.money(perDay, currency);

    if (pct >= 80) {
      return "Getting tight 👀 ... About $perDayStr/day left.";
    }

    if (pct >= 50) {
      return "On track 👍 About $perDayStr/day for $daysLeft days.";
    }

    return "You're doing well 👌 About $perDayStr/day for $daysLeft days.";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stable selection helper
  // ─────────────────────────────────────────────────────────────────────────

  /// Picks a message that stays the same all day.
  /// Uses today's day-of-year as the deterministic index so it rotates
  /// naturally to the next message the following day.
  static String _pick(List<String> messages) {
    final dayOfYear = _dayOfYear(DateTime.now());
    return messages[dayOfYear % messages.length];
  }

  static int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays;
  }
}
