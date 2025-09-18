import 'package:flutter/material.dart';

import '../../provider/translation_service.dart';

class LanguageSelectorWidget {
  static Future<String?> showLanguageSelector({required BuildContext context}) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const LanguageSelectorDialog();
      },
    );
  }
}

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Filter out the 'auto' language and create a new list
    final languages = availableLanguages.skip(1).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: colorScheme.surface,
      elevation: 4.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // // Header with theme-aware styling
            // Container(
            //   padding: const EdgeInsets.all(16.0),
            //   decoration: BoxDecoration(
            //     color: colorScheme.primary.withOpacity(0.1),
            //     borderRadius: const BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0)),
            //   ),
            //   child: Text(
            //     'Choose language', // Fixed title
            //     style: textTheme.titleMedium!.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
            //     textAlign: TextAlign.center,
            //   ),
            // ),
            //
            // // Divider with theme color
            // Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withOpacity(0.12)),

            // Language List
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(language.code);
                      },
                      splashColor: colorScheme.primary.withOpacity(0.2),
                      highlightColor: colorScheme.primary.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ListTile(
                          leading: Text(language.flag, style: const TextStyle(fontSize: 24)),
                          title: Text(language.name, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Close Button with theme-aware styling
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: TextButton(
            //     onPressed: () {
            //       Navigator.of(context).pop();
            //     },
            //     style: TextButton.styleFrom(
            //       foregroundColor: colorScheme.primary,
            //       padding: const EdgeInsets.symmetric(vertical: 16.0),
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            //     ),
            //     child: Text(
            //       'Close',
            //       style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
