import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// 다이얼로그 쇼케이스 페이지
class DialogsPage extends StatelessWidget {
  const DialogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('다이얼로그')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, '알림 다이얼로그'),
          MGButton.primary(
            label: '알림 표시',
            onPressed: () => MGModal.alert(
              context: context,
              title: '알림',
              message: '게임이 저장되었습니다.',
            ),
          ),
          MGSpacing.vLg,
          _buildSection(context, '확인 다이얼로그'),
          MGButton.primary(
            label: '확인 다이얼로그',
            onPressed: () async {
              final result = await MGModal.confirm(
                context: context,
                title: '게임 종료',
                message: '정말 게임을 종료하시겠습니까?\n저장하지 않은 진행 상황은 사라집니다.',
              );
              if (context.mounted) {
                MGSnackBar.info(context, '결과: ${result ? "확인" : "취소"}');
              }
            },
          ),
          MGSpacing.vMd,
          MGButton.secondary(
            label: '위험 동작 확인',
            onPressed: () async {
              final result = await MGModal.confirm(
                context: context,
                title: '데이터 삭제',
                message: '모든 게임 데이터가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
                confirmText: '삭제',
                dangerous: true,
              );
              if (context.mounted) {
                if (result) {
                  MGSnackBar.warning(context, '데이터가 삭제되었습니다');
                }
              }
            },
          ),
          MGSpacing.vLg,
          _buildSection(context, '입력 다이얼로그'),
          MGButton.primary(
            label: '이름 입력',
            onPressed: () async {
              final name = await MGModal.input(
                context: context,
                title: '플레이어 이름',
                message: '게임에서 사용할 이름을 입력하세요.',
                hintText: '이름 입력...',
                maxLength: 20,
              );
              if (context.mounted && name != null && name.isNotEmpty) {
                MGSnackBar.success(context, '이름: $name');
              }
            },
          ),
          MGSpacing.vLg,
          _buildSection(context, '선택 다이얼로그'),
          MGButton.primary(
            label: '난이도 선택',
            onPressed: () async {
              final difficulty = await MGModal.select<String>(
                context: context,
                title: '난이도 선택',
                options: const [
                  MGSelectOption(
                    value: 'easy',
                    label: '쉬움',
                    description: '초보자에게 추천',
                    icon: Icons.sentiment_very_satisfied,
                  ),
                  MGSelectOption(
                    value: 'normal',
                    label: '보통',
                    description: '일반적인 난이도',
                    icon: Icons.sentiment_satisfied,
                  ),
                  MGSelectOption(
                    value: 'hard',
                    label: '어려움',
                    description: '도전을 원하는 플레이어용',
                    icon: Icons.sentiment_dissatisfied,
                  ),
                ],
              );
              if (context.mounted && difficulty != null) {
                MGSnackBar.info(context, '선택: $difficulty');
              }
            },
          ),
          MGSpacing.vLg,
          _buildSection(context, '성공/오류 다이얼로그'),
          Row(
            children: [
              Expanded(
                child: MGButton.primary(
                  label: '성공',
                  icon: Icons.check,
                  onPressed: () => MGModal.success(
                    context: context,
                    title: '구매 완료',
                    message: '아이템이 성공적으로 구매되었습니다!',
                  ),
                ),
              ),
              MGSpacing.hSm,
              Expanded(
                child: MGButton.secondary(
                  label: '오류',
                  icon: Icons.error,
                  onPressed: () => MGModal.error(
                    context: context,
                    title: '구매 실패',
                    message: '골드가 부족합니다.',
                  ),
                ),
              ),
            ],
          ),
          MGSpacing.vLg,
          _buildSection(context, '로딩 다이얼로그'),
          MGButton.primary(
            label: '로딩 표시 (2초)',
            onPressed: () async {
              MGModal.loading(
                context: context,
                message: '저장 중...',
              );
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                MGModal.closeLoading(context);
                MGSnackBar.success(context, '저장 완료!');
              }
            },
          ),
          MGSpacing.vLg,
          _buildSection(context, '바텀 시트'),
          MGButton.primary(
            label: '바텀 시트 열기',
            onPressed: () => MGBottomSheet.show(
              context: context,
              title: '옵션',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('공유'),
                    onTap: () {
                      Navigator.pop(context);
                      MGSnackBar.info(context, '공유 클릭');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('수정'),
                    onTap: () {
                      Navigator.pop(context);
                      MGSnackBar.info(context, '수정 클릭');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('삭제', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      MGSnackBar.warning(context, '삭제 클릭');
                    },
                  ),
                ],
              ),
            ),
          ),
          MGSpacing.vMd,
          MGButton.secondary(
            label: '선택 바텀 시트',
            onPressed: () async {
              final result = await MGBottomSheet.select<String>(
                context: context,
                title: '언어 선택',
                options: const [
                  MGSelectOption(value: 'ko', label: '한국어', icon: Icons.language),
                  MGSelectOption(value: 'en', label: 'English', icon: Icons.language),
                  MGSelectOption(value: 'ja', label: '日本語', icon: Icons.language),
                ],
                selectedValue: 'ko',
              );
              if (context.mounted && result != null) {
                MGSnackBar.info(context, '선택: $result');
              }
            },
          ),
          MGSpacing.vLg,
          _buildSection(context, '스낵바'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MGButton.text(
                label: '성공',
                onPressed: () => MGSnackBar.success(context, '저장되었습니다'),
              ),
              MGButton.text(
                label: '오류',
                onPressed: () => MGSnackBar.error(context, '오류가 발생했습니다'),
              ),
              MGButton.text(
                label: '경고',
                onPressed: () => MGSnackBar.warning(context, '주의가 필요합니다'),
              ),
              MGButton.text(
                label: '정보',
                onPressed: () => MGSnackBar.info(context, '새 업데이트가 있습니다'),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
