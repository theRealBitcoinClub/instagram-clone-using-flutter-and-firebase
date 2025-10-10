import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../provider/translation_service.dart';

class LanguageSelectorWidget {
  static Future<String?> showLanguageSelector({required BuildContext context}) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const LanguageSelectorDialog();
      },
    );
    //     .then((value) {
    //   // Double-check keyboard is dismissed after dialog
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     LanguageSelectorDialog._forceDismissKeyboard(context);
    //   });
    //   return value;
    // });
  }
}

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({Key? key}) : super(key: key);

  static void _forceDismissKeyboard(BuildContext context) {
    // Try multiple methods to ensure keyboard is dismissed
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.mounted) FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Additional safety measure
    Future.delayed(const Duration(milliseconds: 50), () {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LanguageSelectorDialog._forceDismissKeyboard(context);
    });

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
                      onTap: () async {
                        // LanguageSelectorDialog._forceDismissKeyboard(context);
                        // await Future.delayed(Duration(milliseconds: 100), () {
                        //   if (context.mounted) {
                        Navigator.of(context).pop(language.code);
                        // }
                        // });
                        // LanguageSelectorDialog._forceDismissKeyboard(context);
                        // if (context.mounted) FocusScope.of(context).unfocus();
                        // SystemChannels.textInput.invokeMethod('TextInput.hide');
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
          ],
        ),
      ),
    );
  }
}
