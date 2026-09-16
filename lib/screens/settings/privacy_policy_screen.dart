import 'package:flutter/material.dart';

class PrivacyPolicyScreen
    extends StatelessWidget {
  const PrivacyPolicyScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '개인정보처리방침',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          40,
        ),
        children: [
          const Text(
            'SNOB 개인정보처리방침',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'SNOB은 사용자의 개인정보를 소중하게 보호합니다.',
            style: TextStyle(
              fontSize: 13,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

          _section(
            '1. 수집하는 정보',
            'SNOB은 서비스 제공을 위해 필요한 범위에서 '
            '카카오 계정의 닉네임 및 프로필 이미지 등의 '
            '정보를 이용할 수 있습니다.\n\n'
            '또한 사용자가 직접 저장하는 여행 일정, '
            '여행 기록, 사진 및 일기 등의 정보를 '
            '기기에 저장할 수 있습니다.',
          ),

          _section(
            '2. 개인정보의 이용',
            '수집된 정보는 로그인 상태 유지, '
            '여행 성향 기반 추천, 여행 일정 및 '
            '여행 기록 기능 제공을 위해 사용됩니다.',
          ),

          _section(
            '3. 정보의 보관',
            '앱에서 생성한 여행 일정 및 일부 설정 정보는 '
            '사용자의 기기에 저장될 수 있습니다.',
          ),

          _section(
            '4. 개인정보의 삭제',
            '사용자는 서비스에서 로그아웃하거나 '
            '회원 탈퇴를 통해 계정 연결을 해제할 수 있습니다.',
          ),

          _section(
            '5. 문의',
            '개인정보와 관련하여 문의사항이 있는 경우 '
            'SNOB 운영자에게 문의해주세요.',
          ),
        ],
      ),
    );
  }

  static Widget _section(
    String title,
    String body,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
              height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}