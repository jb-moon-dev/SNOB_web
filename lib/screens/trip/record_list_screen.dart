import 'dart:io';

import 'package:flutter/material.dart';
import 'package:snob/services/trip_record_storage.dart';
import 'package:snob/screens/trip/record_detail_screen.dart';

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() =>
      _RecordListScreenState();
}

class _RecordListScreenState
    extends State<RecordListScreen> {
  List<TripRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ============================================================
  // 기록 불러오기
  // ============================================================

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records =
          await TripRecordStorage.loadRecords();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('여행 기록 불러오기 실패: $e');

      if (!mounted) return;

      setState(() {
        _records = [];
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 기록 상세 화면
  // ============================================================

  Future<void> _openDetail(
    TripRecord record,
    int index,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailScreen(
          record: record,
          recordIndex: index,
        ),
      ),
    );

    // 상세 화면에서 삭제했을 수도 있으므로
    // 돌아오면 다시 불러온다.
    await _loadRecords();
  }

  // ============================================================
  // 날짜 포맷
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 기록 카드
  // ============================================================

  Widget _buildRecordCard(
    TripRecord record,
    int index,
  ) {
    final hasPhoto =
        record.photoPaths.isNotEmpty;

    final diary = record.diary.trim();

    return GestureDetector(
      onTap: () {
        _openDetail(record, index);
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // 대표 사진
            // ----------------------------------------------------

            if (hasPhoto)
              SizedBox(
                width: double.infinity,
                height: 190,
                child: Image.file(
                  File(record.photoPaths.first),
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) {
                    return _buildPhotoPlaceholder();
                  },
                ),
              )
            else
              _buildPhotoPlaceholder(),

            // ----------------------------------------------------
            // 내용
            // ----------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.regionName.isEmpty
                              ? '나의 여행'
                              : record.regionName,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        Icons
                            .chevron_right_rounded,
                        color:
                            Colors.grey.shade400,
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

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
                          fontSize: 12,
                          color:
                              Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.place_outlined,
                        size: 15,
                        color:
                            Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.visitedPlaces.length}곳',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade500,
                        ),
                      ),
                      if (record.photoPaths
                          .isNotEmpty) ...[
                        const SizedBox(
                            width: 14),
                        Icon(
                          Icons
                              .photo_library_outlined,
                          size: 15,
                          color: Colors
                              .grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${record.photoPaths.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (record.personalityType !=
                      null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: Text(
                        record.personalityType!,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  if (diary.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      diary,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 사진 없음
  // ============================================================

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 190,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons
                .photo_camera_back_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '사진이 없는 여행',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 빈 화면
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.62,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons
                            .auto_stories_outlined,
                        size: 38,
                        color:
                            Colors.grey.shade400,
                      ),
                    ),

                    const SizedBox(
                        height: 22),

                    const Text(
                      '아직 여행 기록이 없어요',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                        height: 9),

                    Text(
                      '여행을 다녀온 후\n'
                      '사진과 이야기를 기록해보세요.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade500,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          '기록',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _records.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      40,
                    ),
                    children: [
                      Text(
                        '나의 여행 이야기',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(
                          height: 18),

                      ..._records
                          .asMap()
                          .entries
                          .map(
                        (entry) {
                          return _buildRecordCard(
                            entry.value,
                            entry.key,
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}