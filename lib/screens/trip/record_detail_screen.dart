import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/trip_record_storage.dart';

class RecordDetailScreen extends StatefulWidget {
  final TripRecord record;
  final int recordIndex;

  const RecordDetailScreen({
    super.key,
    required this.record,
    required this.recordIndex,
  });

  @override
  State<RecordDetailScreen> createState() =>
      _RecordDetailScreenState();
}

class _RecordDetailScreenState
    extends State<RecordDetailScreen> {
  // ============================================================
  // 날짜
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 기록 삭제
  // ============================================================

  Future<void> _deleteRecord() async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            '여행 기록을 삭제할까요?',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            '삭제한 여행 기록은 다시 복구할 수 없어요.',
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
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await TripRecordStorage.deleteRecord(
      widget.recordIndex,
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  // ============================================================
  // 사진 전체 보기
  // ============================================================

  void _openPhoto(
    String path,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewerScreen(
          photoPaths:
              widget.record.photoPaths,
          initialIndex: index,
        ),
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '여행 기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _deleteRecord,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
            tooltip: '기록 삭제',
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 50,
        ),
        children: [
          // ======================================================
          // 여행 제목
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              0,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  record.regionName.isEmpty
                      ? '나의 여행'
                      : record.regionName,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons
                          .calendar_today_outlined,
                      size: 14,
                      color:
                          Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(
                        record.createdAt,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // 사진
          // ======================================================

          if (record.photoPaths.isNotEmpty)
            _buildPhotos(record),

          // ======================================================
          // 여행 정보
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              28,
              20,
              0,
            ),
            child: _buildTravelSummary(
              record,
            ),
          ),

          // ======================================================
          // 방문 장소
          // ======================================================

          if (record.visitedPlaces
              .isNotEmpty) ...[
            const SizedBox(height: 32),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: _buildSectionTitle(
                '이번 여행에서 방문한 곳',
              ),
            ),

            const SizedBox(height: 12),

            _buildVisitedPlaces(record),
          ],

          // ======================================================
          // 여행 성향
          // ======================================================

          if (record.personalityType !=
                  null ||
              record.recommendedRegion !=
                  null) ...[
            const SizedBox(height: 32),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: _buildSectionTitle(
                '나의 여행 성향',
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child:
                  _buildPersonalityCard(
                record,
              ),
            ),
          ],

          // ======================================================
          // 일기
          // ======================================================

          if (record.diary.trim().isNotEmpty) ...[
            const SizedBox(height: 32),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: _buildSectionTitle(
                '여행 일기',
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: _buildDiary(
                record.diary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 사진 영역
  // ============================================================

  Widget _buildPhotos(
    TripRecord record,
  ) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount:
            record.photoPaths.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder:
            (context, index) {
          final path =
              record.photoPaths[index];

          return GestureDetector(
            onTap: () {
              _openPhoto(
                path,
                index,
              );
            },
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: Image.file(
                File(path),
                width: 270,
                height: 270,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return Container(
                    width: 270,
                    height: 270,
                    color:
                        Colors.grey.shade100,
                    child: Icon(
                      Icons
                          .broken_image_outlined,
                      size: 40,
                      color: Colors
                          .grey.shade400,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // 여행 요약
  // ============================================================

  Widget _buildTravelSummary(
    TripRecord record,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat(
              icon:
                  Icons.place_outlined,
              value:
                  '${record.visitedPlaces.length}',
              label: '방문 장소',
            ),
          ),

          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),

          Expanded(
            child: _buildStat(
              icon: Icons
                  .photo_library_outlined,
              value:
                  '${record.photoPaths.length}',
              label: '여행 사진',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 방문 장소
  // ============================================================

  Widget _buildVisitedPlaces(
    TripRecord record,
  ) {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (
            int i = 0;
            i < record.visitedPlaces.length;
            i++
          )
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style:
                                const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          width: 12),

                      Expanded(
                        child: Text(
                          record.visitedPlaces[
                              i],
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (i !=
                    record.visitedPlaces.length -
                        1)
                  Divider(
                    height: 1,
                    indent: 60,
                    color:
                        Colors.grey.shade200,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 여행 성향
  // ============================================================

  Widget _buildPersonalityCard(
    TripRecord record,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (record.personalityType !=
              null) ...[
            Text(
              '여행 유형',
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record.personalityType!,
              style: const TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],

          if (record.personalityType !=
                  null &&
              record.recommendedRegion !=
                  null)
            const SizedBox(height: 18),

          if (record.recommendedRegion !=
              null) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              '추천 지역',
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record.recommendedRegion!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 일기
  // ============================================================

  Widget _buildDiary(
    String diary,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        diary,
        style: const TextStyle(
          fontSize: 14,
          height: 1.8,
        ),
      ),
    );
  }

  // ============================================================
  // Section title
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ==================================================================
// 사진 전체 화면
// ==================================================================

class _PhotoViewerScreen
    extends StatefulWidget {
  final List<String> photoPaths;
  final int initialIndex;

  const _PhotoViewerScreen({
    required this.photoPaths,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerScreen> createState() =>
      _PhotoViewerScreenState();
}

class _PhotoViewerScreenState
    extends State<_PhotoViewerScreen> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex =
        widget.initialIndex;

    _controller = PageController(
      initialPage:
          widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photoPaths.length}',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ),

      body: PageView.builder(
        controller: _controller,
        itemCount:
            widget.photoPaths.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder:
            (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.file(
                File(
                  widget.photoPaths[index],
                ),
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons
                        .broken_image_outlined,
                    color: Colors.white,
                    size: 50,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}