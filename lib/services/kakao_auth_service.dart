import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthService {
  // ============================================================
  // 웹 카카오 로그인
  //
  // 흐름:
  // Flutter Web
  //   ↓
  // Kakao OAuth authorize
  //   ↓
  // authorization code
  //   ↓
  // Vercel Backend
  //   ↓
  // Kakao REST API
  //   ↓
  // kakaoUser
  // ============================================================

  static Future<User?> login(BuildContext context) async {
    try {
      print('');
      print('========================================');
      print('웹 카카오 로그인 시작');
      print('========================================');

      const redirectUri =
          'https://jb-moon-dev.github.io/SNOB_web/';

      final uri = Uri.base;

      // ==========================================================
      // 현재 브라우저 URL 확인
      // ==========================================================

      print('현재 URL : ${uri.toString()}');
      print('현재 URL query : ${uri.query}');
      print(
        'code 존재 여부 : '
        '${uri.queryParameters.containsKey('code')}',
      );
      print(
        'state 존재 여부 : '
        '${uri.queryParameters.containsKey('state')}',
      );

      // ==========================================================
      // 카카오에서 돌아온 authorization code 확인
      // ==========================================================

      final code = uri.queryParameters['code'];

      // ==========================================================
      // 아직 authorization code가 없다면
      // 카카오 로그인 페이지로 이동
      // ==========================================================

      if (code == null || code.isEmpty) {
        print('authorization code 없음');
        print('카카오 로그인 페이지로 이동');

        await AuthCodeClient.instance.authorize(
          redirectUri: redirectUri,
        );

        return null;
      }

      // ==========================================================
      // authorization code 확인
      // ==========================================================

      print('authorization code 확인');
      print('백엔드로 authorization code 전달');

      // ==========================================================
      // Vercel 백엔드에 authorization code 전달
      // ==========================================================

      final response = await http.post(
        Uri.parse(
          'https://snob-backend.vercel.app/api/kakao-login',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
        }),
      );

      // ==========================================================
      // 백엔드 응답 확인
      // ==========================================================

      print(
        '백엔드 응답 상태 : ${response.statusCode}',
      );

      print(
        '백엔드 응답 : ${response.body}',
      );

      if (response.statusCode != 200) {
        print('백엔드 카카오 로그인 실패');
        return null;
      }

      // ==========================================================
      // JSON 파싱
      // ==========================================================

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      print(
        '백엔드 응답 success : ${data['success']}',
      );

      if (data['success'] != true) {
        print('카카오 로그인 실패');
        print('응답 : $data');
        return null;
      }

      // ==========================================================
      // 백엔드에서 받은 카카오 사용자 정보
      // ==========================================================

      final kakaoUser =
          data['kakaoUser'] as Map<String, dynamic>?;

      if (kakaoUser == null) {
        print('카카오 사용자 정보 없음');
        return null;
      }

      print('카카오 사용자 정보 확인');
      print('카카오 사용자 정보 : $kakaoUser');

      // ==========================================================
      // Kakao SDK User 객체로 변환
      // ==========================================================

      final User user = User.fromJson(kakaoUser);

      print('');
      print('========================================');
      print('웹 카카오 로그인 성공');
      print('사용자 id : ${user.id}');
      print('========================================');

      final nickname =
          user.kakaoAccount?.profile?.nickname;

      if (nickname != null) {
        print('사용자 닉네임 : $nickname');
      }

      return user;
    } catch (e, stackTrace) {
      print('');
      print('========================================');
      print('웹 카카오 로그인 오류');
      print('오류 타입 : ${e.runtimeType}');
      print('오류 내용 : $e');
      print('StackTrace : $stackTrace');
      print('========================================');

      return null;
    }
  }

  // ============================================================
  // 로그인 상태 확인
  //
  // 현재 웹 로그인은 authorization code를 백엔드에서
  // 처리하는 구조이므로 Flutter SDK의 TokenManager를
  // 이용한 기존 앱 로그인 방식은 사용하지 않는다.
  //
  // 필요하면 이후 별도의 웹 세션/JWT 방식으로 구현할 수 있다.
  // ============================================================

  static Future<bool> checkToken() async {
    print('웹 로그인 상태 확인');

    // 현재는 웹에서 별도의 세션 토큰을 저장하지 않으므로
    // 기본적으로 false를 반환한다.
    //
    // 로그인 상태를 유지하려면 이후
    // localStorage / secure cookie / 자체 JWT 등을
    // 사용하는 방식으로 구현해야 한다.

    return false;
  }

  // ============================================================
  // 로그아웃
  //
  // 현재 웹 로그인은 백엔드에서 authorization code를
  // 처리하는 구조이므로 Flutter SDK logout()을 사용하지 않는다.
  // ============================================================

  static Future<void> logout() async {
    try {
      print('웹 카카오 로그아웃');

      // 현재 별도의 카카오 SDK 토큰을 Flutter에서 관리하지 않으므로
      // 여기서는 별도 SDK logout을 호출하지 않는다.

      print('웹 카카오 로그아웃 완료');
    } catch (e) {
      print('웹 카카오 로그아웃 오류 : $e');
    }
  }
}