import 'package:intl/intl.dart'; // For parsing specific dates like "MMM d" (e.g., "Oct 25")

DateTime? convertRelativeTimeToAbsolute(String? relativeTimeString) {
  if (relativeTimeString == null || relativeTimeString.trim().isEmpty) {
    return null;
  }

  String input = relativeTimeString.toLowerCase().trim();
  DateTime now = DateTime.now();

  try {
    // --- Handle "just now", "a moment ago", etc. ---
    if (input.contains("just now") || input.contains("moment ago") || input.contains("moments ago")) {
      return now;
    }

    // --- Handle "yesterday" ---
    if (input.contains("yesterday")) {
      // This is an approximation. It could be up to 47 hours 59 mins ago.
      // For simplicity, we'll subtract 24 hours.
      // A more accurate "yesterday" might set the time to a specific point (e.g., start of day).
      return now.subtract(const Duration(days: 1));
    }

    // --- Handle "X unit(s) ago" patterns ---
    RegExpMatch? match = RegExp(r"(\d+)\s+(second|minute|hour|day|week|month|year)s?\s+ago").firstMatch(input);

    if (match != null && match.groupCount >= 2) {
      int value = int.parse(match.group(1)!);
      String unit = match.group(2)!;

      switch (unit) {
        case "second":
          return now.subtract(Duration(seconds: value));
        case "minute":
          return now.subtract(Duration(minutes: value));
        case "hour":
          return now.subtract(Duration(hours: value));
        case "day":
          return now.subtract(Duration(days: value));
        case "week":
          return now.subtract(Duration(days: value * 7));
        case "month":
          // Subtracting months is tricky due to variable days.
          // This is an approximation (average 30 days).
          // For more accuracy, you might need a date utility package
          // or iterate back month by month.
          int currentMonth = now.month;
          int currentYear = now.year;
          for (int i = 0; i < value; i++) {
            currentMonth--;
            if (currentMonth == 0) {
              currentMonth = 12;
              currentYear--;
            }
          }
          // Attempt to keep the same day, but clamp if it's invalid for the new month
          int day = now.day;
          if (day > _daysInMonth(currentYear, currentMonth)) {
            day = _daysInMonth(currentYear, currentMonth);
          }
          return DateTime(currentYear, currentMonth, day, now.hour, now.minute, now.second);
        case "year":
          return DateTime(now.year - value, now.month, now.day, now.hour, now.minute, now.second);
      }
    }

    // --- Handle specific dates like "Month Day" (e.g., "Oct 25") ---
    // This assumes the current year if no year is specified.
    // It also assumes English month abbreviations.
    try {
      // Try parsing with common formats
      // Format: "MMM d" (e.g., "Oct 25") - Assumes current year
      DateTime parsedDate = DateFormat("MMM d", "en_US").parseLoose(input);
      // If the parsed date is in the future relative to "now" (e.g., it's Jan and date is "Dec 25"),
      // assume it was last year.
      if (parsedDate.isAfter(now) && (now.month < parsedDate.month || (now.month == parsedDate.month && now.day < parsedDate.day))) {
        return DateTime(now.year - 1, parsedDate.month, parsedDate.day);
      }
      return DateTime(now.year, parsedDate.month, parsedDate.day);
    } catch (e) {
      // Could not parse as "MMM d"
    }

    // --- Handle "today" (less common for "ago" but good to have) ---
    if (input.contains("today")) {
      // Could mean anything from start of today to now.
      // Let's assume it means "sometime earlier today or now"
      // If a time is also present like "today at 5 PM", you'd need more parsing.
      // For simplicity, if it's just "today", it implies very recent.
      return now; // Or you could set it to the start of today: DateTime(now.year, now.month, now.day);
    }

    // --- Fallback: If no pattern matches, try DateTime.parse directly ---
    // This is unlikely to work for relative strings but worth a try.
    try {
      return DateTime.parse(relativeTimeString);
    } catch (e) {
      print("Could not parse relative time string: $relativeTimeString with any known pattern.");
      return null; // Or throw an exception, or return now as a last resort
    }
  } catch (e) {
    print("Error in convertRelativeTimeToAbsolute for '$relativeTimeString': $e");
    return null;
  }
}

// Helper function for days in month (simplistic, doesn't handle leap years perfectly for complex cases but okay for clamping)
int _daysInMonth(int year, int month) {
  if (month == DateTime.february) {
    // Basic leap year check for February
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
  } else if ([DateTime.april, DateTime.june, DateTime.september, DateTime.november].contains(month)) {
    return 30;
  } else {
    return 31;
  }
}

// --- EXAMPLE USAGE ---
void main() {
  List<String> testDates = [
    "7 days ago",
    "1 day ago",
    "yesterday",
    "2 hours ago",
    "30 minutes ago",
    "15 seconds ago",
    "just now",
    "a moment ago",
    "1 week ago",
    "3 weeks ago",
    "1 month ago",
    "5 months ago",
    "1 year ago",
    "2 years ago",
    "Oct 25", // Assumes current year, or last year if Oct 25 is in future this year
    "Dec 30", // Assumes current year, or last year if Dec 30 is in future this year
    "Jan 5", // Assumes current year
    "today",
    "An unknown date string", // Should fail gracefully
  ];

  for (String dateStr in testDates) {
    DateTime? absoluteDate = convertRelativeTimeToAbsolute(dateStr);
    print('"$dateStr" -> ${absoluteDate?.toIso8601String() ?? "Could not parse"}');
  }

  // Example for a future date (if today is before Oct 25)
  // To test the "last year" logic for "MMM d"
  // DateTime today = DateTime.now();
  // if (today.month < 10 || (today.month == 10 && today.day < 25)) {
  //   print("--- Testing future month/day for 'last year' logic ---");
  //   DateTime? oct25 = convertRelativeTimeToAbsolute("Oct 25");
  //   print('"Oct 25" (assuming current year is before this date) -> ${oct25?.toIso8601String()}');
  // }
}
