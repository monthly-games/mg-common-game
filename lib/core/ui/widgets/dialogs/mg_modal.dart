import 'package:flutter/material.dart';
import '../../layout/mg_spacing.dart';
import '../buttons/mg_button.dart';

/// MG-Games 모달 다이얼로그
/// UI_UX_MASTER_GUIDE.md 기반
class MGModal {
  MGModal._();

  /// 기본 다이얼로그 표시
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? backgroundColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _MGModalDialog(
        title: title,
        content: content,
        actions: actions,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// 확인 다이얼로그
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    bool dangerous = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      content: Text(message),
      actions: [
        MGButton.text(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        MGButton(
          label: confirmText,
          style: MGButtonStyle.filled,
          backgroundColor: dangerous ? Colors.red : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    return result ?? false;
  }

  /// 알림 다이얼로그
  static Future<void> alert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = '확인',
  }) {
    return show(
      context: context,
      title: title,
      content: Text(message),
      actions: [
        MGButton.primary(
          label: buttonText,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// 입력 다이얼로그
  static Future<String?> input({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = '확인',
    String cancelText = '취소',
    int maxLength = 100,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await show<String>(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(message),
            ),
          TextField(
            controller: controller,
            maxLength: maxLength,
            keyboardType: keyboardType,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        MGButton.text(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        MGButton.primary(
          label: confirmText,
          onPressed: () => Navigator.of(context).pop(controller.text),
        ),
      ],
    );

    controller.dispose();
    return result;
  }

  /// 선택 다이얼로그
  static Future<T?> select<T>({
    required BuildContext context,
    required String title,
    required List<MGSelectOption<T>> options,
    T? selectedValue,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option.value == selectedValue;
          return ListTile(
            leading: option.icon != null ? Icon(option.icon) : null,
            title: Text(option.label),
            subtitle: option.description != null
                ? Text(option.description!)
                : null,
            trailing: isSelected ? const Icon(Icons.check) : null,
            selected: isSelected,
            onTap: () => Navigator.of(context).pop(option.value),
          );
        }).toList(),
      ),
    );
  }

  /// 로딩 다이얼로그
  static Future<void> loading({
    required BuildContext context,
    required String message,
    Future<void>? future,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MGLoadingDialog(message: message),
    );

    if (future != null) {
      await future;
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// 로딩 다이얼로그 닫기
  static void closeLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 성공 다이얼로그
  static Future<void> success({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = '확인',
  }) {
    return show(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(message),
            ),
        ],
      ),
      actions: [
        MGButton.primary(
          label: buttonText,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// 오류 다이얼로그
  static Future<void> error({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = '확인',
  }) {
    return show(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 64,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(message),
            ),
        ],
      ),
      actions: [
        MGButton.primary(
          label: buttonText,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// 모달 다이얼로그 위젯
class _MGModalDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const _MGModalDialog({
    required this.title,
    required this.content,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeArea = MediaQuery.of(context).padding;

    return Dialog(
      backgroundColor: backgroundColor ?? theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height -
              safeArea.top -
              safeArea.bottom -
              48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 구분선
            const Divider(height: 1),
            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
            ),
            // 액션 버튼
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 로딩 다이얼로그 위젯
class _MGLoadingDialog extends StatelessWidget {
  final String message;

  const _MGLoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            MGSpacing.vMd,
            Text(message),
          ],
        ),
      ),
    );
  }
}

/// 선택 옵션
class MGSelectOption<T> {
  final T value;
  final String label;
  final String? description;
  final IconData? icon;

  const MGSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });
}

/// 바텀 시트 표시
class MGBottomSheet {
  MGBottomSheet._();

  /// 바텀 시트 표시
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: height != null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            if (enableDrag)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // 제목
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            // 내용
            child,
          ],
        );

        if (height != null) {
          content = SizedBox(
            height: height,
            child: content,
          );
        }

        return SafeArea(child: content);
      },
    );
  }

  /// 선택 바텀 시트
  static Future<T?> select<T>({
    required BuildContext context,
    required String title,
    required List<MGSelectOption<T>> options,
    T? selectedValue,
  }) {
    return show<T>(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option.value == selectedValue;
          return ListTile(
            leading: option.icon != null ? Icon(option.icon) : null,
            title: Text(option.label),
            subtitle:
                option.description != null ? Text(option.description!) : null,
            trailing: isSelected
                ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                : null,
            onTap: () => Navigator.of(context).pop(option.value),
          );
        }).toList(),
      ),
    );
  }
}
