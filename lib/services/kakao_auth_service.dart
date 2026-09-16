import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthService {
  // ============================================================
  // 카카오 로그인
  // ============================================================

  static Future<User?> login(BuildContext context) async {
    try {
      print('');
      print('========================================');
      print('카카오 로그인 시작');
      print('========================================');

      // ==========================================================
      // 1. 카카오계정 로그인 직접 실행
      //
      // 현재 에뮬레이터에서는 카카오톡이 설치되어 있지만
      // 카카오톡 계정 연결 상태 때문에 loginWithKakaoTalk()
      // 이 실패할 수 있으므로 우선 카카오계정 로그인으로
      // 직접 테스트한다.
      // ==========================================================

      print('카카오계정 로그인 시작');

      OAuthToken token =
          await UserApi.instance.loginWithKakaoAccount();

      print('카카오계정 로그인 성공');
      print('Access Token 발급 완료');

      // ==========================================================
      // 2. 사용자 정보 가져오기
      // ==========================================================

      User user = await UserApi.instance.me();

      print('사용자 id : ${user.id}');

      final nickname =
          user.kakaoAccount?.profile?.nickname;

      if (nickname != null) {
        print('사용자 닉네임 : $nickname');
      }

      return user;
    } on PlatformException catch (e) {
      print('');
      print('========================================');
      print('카카오 로그인 PlatformException');
      print('code : ${e.code}');
      print('message : ${e.message}');
      print('details : ${e.details}');
      print('========================================');

      return null;
    } on KakaoException catch (e) {
      print('');
      print('========================================');
      print('카카오 로그인 KakaoException');
      print('$e');
      print('========================================');

      return null;
    } catch (e) {
      print('');
      print('========================================');
      print('카카오 로그인 일반 오류');
      print('$e');
      print('========================================');

      return null;
    }
  }

  // ============================================================
  // 로그인 상태 확인
  // ============================================================

  static Future<bool> checkToken() async {
    try {
      print('카카오 로그인 상태 확인 시작');

      OAuthToken? token =
          await TokenManagerProvider
              .instance
              .manager
              .getToken();

      if (token == null) {
        print('저장된 카카오 토큰 없음');
        return false;
      }

      print('카카오 토큰 존재');

      // 실제 토큰 유효성 확인
      try {
        await UserApi.instance.accessTokenInfo();

        print('로그인 상태 확인됨 (토큰 유효)');
        return true;
      } catch (e) {
        print('카카오 토큰 만료 또는 무효');

        await logout();

        return false;
      }
    } catch (e) {
      print('토큰 확인 오류 : $e');
      return false;
    }
  }

  // ============================================================
  // 로그아웃
  // ============================================================

  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();

      print('카카오 로그아웃 완료');
    } catch (e) {
      print('카카오 로그아웃 오류 : $e');
    }
  }
}