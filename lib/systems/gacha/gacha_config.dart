/// 가챠 시스템 설정 - 호환성 레이어
///
/// 이 파일은 gacha_pool.dart로의 마이그레이션을 위한 호환성 레이어입니다.
/// 새 코드에서는 gacha_pool.dart를 직접 import하세요.
library;

export 'gacha_pool.dart';

// 레거시 별칭 (deprecated)
// GachaRarity.superSuperRare는 GachaRarity.ultraRare로 변경됨
// GachaItem.name 파라미터는 nameKr로 변경됨
