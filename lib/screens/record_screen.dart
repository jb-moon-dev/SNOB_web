import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/trip_record_storage.dart';

// ================================================================
// 기록 화면
// ================================================================

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => RecordScreenState();
}

class RecordScreenState extends State<RecordScreen> {
  // 실제 저장된 여행 기록
  List<TripRecord> _records = [];

  bool _isLoading = true;

  // ==============================================================
  // 초기화
  // ==============================================================

  @override
  void initState() {
    super.initState();

    loadRecords();
  }

  // ==============================================================
  // 여행 기록 불러오기
  // ==============================================================

  Future<void> loadRecords() async {
    final records = await TripRecordStorage.loadRecords();

    if (!mounted) return;

    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  // ==============================================================
  // 날짜 표시
  // ==============================================================

  String _formatDate(DateTime date) {
    return '${date.year}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ==============================================================
  // 여행 기록 삭제
  // ==============================================================

  Future<void> _deleteRecord(int index) async {
    final record = _records[index];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '여행 기록을 삭제할까요?',
          ),
          content: Text(
            '${record.regionName} 여행 기록이 삭제됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await TripRecordStorage.deleteRecord(
      index,
    );

    await loadRecords();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '여행 기록이 삭제되었어요.',
        ),
      ),
    );
  }

  // ==============================================================
  // 기록 상세 화면
  // ==============================================================

  Future<void> _openRecord(
    int index,
  ) async {
    final record = _records[index];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelRecordDetailScreen(
          record: record,
          recordIndex: index,
        ),
      ),
    );

    // 상세 화면에서 수정된 내용을 다시 불러오기
    await loadRecords();
  }

  // ==============================================================
  // Build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색은 main.dart의 scaffoldBackgroundColor 사용

      appBar: AppBar(
        // AppBar 색상과 elevation은 main.dart의 appBarTheme 사용

        title: const Text(
          '기록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // 제목
                    // ==================================================

                    const Text(
                      '나의 여행을 다시 만나보세요',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // 여행 요약 카드
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '✈️',
                                    style: TextStyle(
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 14,
                              ),

                              const Text(
                                '나의 여행',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          Text(
                            '지금까지 ${_records.length}개의 여행을 기록했어요',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            _records.isNotEmpty
                                ? '최근 여행  '
                                    '${_records.first.regionName} · '
                                    '${_formatDate(_records.first.startDate)}'
                                : '아직 기록된 여행이 없어요',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    // ==================================================
                    // 여행 기록 제목
                    // ==================================================

                    const Text(
                      '여행 기록',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // 기록 없음
                    // ==================================================

                    if (_records.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 60,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🗺️',
                              style: TextStyle(
                                fontSize: 45,
                              ),
                            ),

                            const SizedBox(
                              height: 15,
                            ),

                            const Text(
                              '아직 여행 기록이 없어요.',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              '여행을 완료하면\n'
                              '이곳에 여행 기록이 남아요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ==================================================
                    // 여행 기록 카드
                    // ==================================================

                    ..._records.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final record = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: GestureDetector(
                            onTap: () => _openRecord(index),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // --------------------------------
                                  // 대표 사진
                                  // --------------------------------

                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                    child: record.photoPaths.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Image.file(
                                              File(
                                                record.photoPaths.first,
                                              ),
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Center(
                                                  child: Text(
                                                    '📸 사진을 불러올 수 없어요',
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : const Center(
                                            child: Text(
                                              '📸 여행 사진',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                  ),

                                  const SizedBox(
                                    height: 15,
                                  ),

                                  // --------------------------------
                                  // 지역
                                  // --------------------------------

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          record.regionName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        onPressed: () =>
                                            _deleteRecord(index),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 7,
                                  ),

                                  // --------------------------------
                                  // 여행 날짜
                                  // --------------------------------

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),

                                      const SizedBox(
                                        width: 6,
                                      ),

                                      Text(
                                        '${_formatDate(record.startDate)}'
                                        ' - '
                                        '${_formatDate(record.endDate)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  // --------------------------------
                                  // 방문 장소
                                  // --------------------------------

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 17,
                                        color: Colors.grey.shade600,
                                      ),

                                      const SizedBox(
                                        width: 4,
                                      ),

                                      Text(
                                        '${record.visitedPlaces.length}곳 방문',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ==================================================================
// 여행 기록 상세 화면
// ==================================================================

class TravelRecordDetailScreen extends StatefulWidget {
  final TripRecord record;

  final int recordIndex;

  const TravelRecordDetailScreen({
    super.key,
    required this.record,
    required this.recordIndex,
  });

  @override
  State<TravelRecordDetailScreen> createState() =>
      _TravelRecordDetailScreenState();
}

class _TravelRecordDetailScreenState
    extends State<TravelRecordDetailScreen> {
  late TextEditingController _diaryController;

  // ==============================================================
  // 사진 추가
  // ==============================================================

  Future<void> _addPhoto() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      widget.record.photoPaths.add(
        image.path,
      );
    });

    // 사진을 추가한 즉시 저장
    await _saveRecord(
      showMessage: false,
    );
  }

  // ==============================================================
  // 초기화
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _diaryController = TextEditingController(
      text: widget.record.diary,
    );
  }

  // ==============================================================
  // 종료
  // ==============================================================

  @override
  void dispose() {
    _diaryController.dispose();

    super.dispose();
  }

  // ==============================================================
  // 기록 저장
  // ==============================================================

  Future<void> _saveRecord({
    bool showMessage = true,
  }) async {
    final updatedRecord = TripRecord(
      regionName: widget.record.regionName,
      startDate: widget.record.startDate,
      endDate: widget.record.endDate,
      createdAt: widget.record.createdAt,
      diary: _diaryController.text.trim(),
      photoPaths: List<String>.from(
        widget.record.photoPaths,
      ),
      personalityType: widget.record.personalityType,
      recommendedRegion: widget.record.recommendedRegion,
      visitedPlaces: List<String>.from(
        widget.record.visitedPlaces,
      ),
    );

    await TripRecordStorage.updateRecord(
      widget.recordIndex,
      updatedRecord,
    );

    if (!mounted) {
      return;
    }

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '여행 기록이 저장되었습니다.',
          ),
        ),
      );
    }
  }

  // ==============================================================
  // 날짜
  // ==============================================================

  String _formatDate(DateTime date) {
    return '${date.year}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ==============================================================
  // Build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      // 배경색은 main.dart의 scaffoldBackgroundColor 사용

      appBar: AppBar(
        // AppBar 색상과 elevation은 main.dart의 appBarTheme 사용

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          record.regionName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // 대표 사진
            // ======================================================

            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // ------------------------------------------------
                  // 사진이 있으면 실제 사진 표시
                  // ------------------------------------------------

                  if (record.photoPaths.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(
                            record.photoPaths.first,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Text(
                                '📸 사진을 불러올 수 없어요',
                              ),
                            );
                          },
                        ),
                      ),
                    )

                  // ------------------------------------------------
                  // 사진이 없으면 기본 화면
                  // ------------------------------------------------

                  else
                    const Center(
                      child: Text(
                        '🌊 여행 대표사진',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),

                  // ------------------------------------------------
                  // 사진 추가 버튼
                  // ------------------------------------------------

                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: ElevatedButton.icon(
                      onPressed: _addPhoto,
                      icon: const Icon(
                        Icons.add_a_photo,
                      ),
                      label: const Text(
                        '사진 추가',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // 여행 기본 정보
            // ======================================================

            Text(
              '${record.regionName} 여행',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              '${_formatDate(record.startDate)}'
              ' — '
              '${_formatDate(record.endDate)}',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 19,
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  '${record.visitedPlaces.length}곳 방문',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            const Divider(),

            const SizedBox(
              height: 25,
            ),

            // ======================================================
            // 방문 장소
            // ======================================================

            const Text(
              '🗺️ 방문한 여행지',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: record.visitedPlaces.isEmpty
                  ? const Text(
                      '방문한 여행지가 없습니다.',
                    )
                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        for (
                          int i = 0;
                          i < record.visitedPlaces.length;
                          i++
                        )
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(
                                  child: Text(
                                    record.visitedPlaces[i],
                                    style: const TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ======================================================
            // 여행 일기
            // ======================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✍️ 여행 일기',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    '이번 여행은 어땠나요?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  TextField(
                    controller: _diaryController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText:
                          '여행에서 느낀 점을 자유롭게 기록해보세요.',
                      filled: true,
                      fillColor:
                          const Color(0xFFF7F8FA),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // 저장
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _saveRecord(),
                      child: const Text(
                        '기록 저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
