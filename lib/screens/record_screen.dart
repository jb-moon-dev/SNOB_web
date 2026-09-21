import 'dart:convert';

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
  // 기록 목록에서 사진 추가
  // ==============================================================

  Future<void> _addPhotoToRecord(int index) async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    final base64Image = base64Encode(bytes);

    final record = _records[index];

    final updatedRecord = TripRecord(
      regionName: record.regionName,
      startDate: record.startDate,
      endDate: record.endDate,
      createdAt: record.createdAt,
      diary: record.diary,
      photoPaths: [
        ...record.photoPaths,
        base64Image,
      ],
      personalityType: record.personalityType,
      recommendedRegion: record.recommendedRegion,
      visitedPlaces: List<String>.from(
        record.visitedPlaces,
      ),
    );

    await TripRecordStorage.updateRecord(
      index,
      updatedRecord,
    );

    await loadRecords();
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
  // 여행 기간
  // ==============================================================

  int _getTravelDays(TripRecord record) {
    final difference = record.endDate
        .difference(record.startDate)
        .inDays;

    return difference + 1;
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

  Future<void> _openRecord(int index) async {
    final record = _records[index];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return TravelRecordDetailScreen(
            record: record,
            recordIndex: index,
          );
        },
      ),
    );

    // 상세 화면에서 수정된 내용을 다시 불러오기
    await loadRecords();
  }

  // ==============================================================
  // 대표 사진
  // ==============================================================

  Widget _buildRecordImage(
    TripRecord record,
  ) {
    if (record.photoPaths.isEmpty) {
      return Container(
        width: double.infinity,
        color: const Color(0xFFEFF1ED),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 42,
              color: Colors.grey.shade500,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              '여행 사진을 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    try {
      return Image.memory(
        base64Decode(
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
          return Container(
            color: const Color(0xFFEFF1ED),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  '사진을 불러올 수 없어요',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      return Container(
        color: const Color(0xFFEFF1ED),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey.shade500,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '사진을 불러올 수 없어요',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ==============================================================
  // 여행 기록 카드
  // ==============================================================

  Widget _buildRecordCard(
    int index,
    TripRecord record,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRecord(index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8EAE5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // 대표 사진
              // ==================================================

              SizedBox(
                height: 230,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildRecordImage(
                        record,
                      ),
                    ),

                    // 사진 위 지역 표시
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.regionName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 사진 추가 버튼
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _addPhotoToRecord(index);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 16,
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  '사진 추가',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 카드 정보
              // ==================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  16,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------------------------------------------
                    // 여행 제목 + 삭제
                    // ----------------------------------------------

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${record.regionName} 여행',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        IconButton(
                          onPressed: () {
                            _deleteRecord(index);
                          },
                          tooltip: '삭제',
                          visualDensity:
                              VisualDensity.compact,
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.grey.shade500,
                            size: 21,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ----------------------------------------------
                    // 날짜
                    // ----------------------------------------------

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Expanded(
                          child: Text(
                            '${_formatDate(record.startDate)}'
                            ' — '
                            '${_formatDate(record.endDate)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ----------------------------------------------
                    // 여행 정보
                    // ----------------------------------------------

                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.location_on_outlined,
                          text:
                              '${record.visitedPlaces.length}곳 방문',
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        _buildInfoChip(
                          icon: Icons.nights_stay_outlined,
                          text:
                              '${_getTravelDays(record)}일 여행',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // 정보 칩
  // ==============================================================

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 빈 기록 화면
  // ==============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 80,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8EAE5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2ED),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_album_outlined,
              size: 38,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            '아직 여행 기록이 없어요',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          Text(
            '여행을 완료하면 이곳에\n'
            '나만의 여행 기록이 남아요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // Build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final width = constraints.maxWidth;

                  final isMobile = width < 700;
                  final isTablet =
                      width >= 700 && width < 1100;

                  return RefreshIndicator(
                    onRefresh: loadRecords,
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isMobile ? 18 : 32,
                        vertical:
                            isMobile ? 24 : 34,
                      ),
										child: Center(
											child: ConstrainedBox(
												constraints: const BoxConstraints(
													maxWidth: 1280,
												),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														// ==================================================
														// 상단 헤더
														// ==================================================
														LayoutBuilder(
															builder: (
																context,
																headerConstraints,
															) {
																final double contentWidth =
																	headerConstraints.maxWidth;

																final bool compactHeader =
																	contentWidth < 900;

                                final headerText = SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'TRAVEL RECORD',
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(
                                          fontSize:
                                              isMobile ? 11 : 12,
                                          fontWeight:
                                              FontWeight.bold,
                                          letterSpacing: 2.2,
                                          color:
                                              Colors.grey.shade600,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      Text(
                                        '나의 여행 기록',
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow:
                                            TextOverflow.visible,
                                        style: TextStyle(
                                          fontSize:
                                              isMobile ? 28 : 36,
                                          fontWeight:
                                              FontWeight.w800,
                                          letterSpacing: -1.2,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      Text(
                                        '다녀온 여행을 사진과 함께 다시 만나보세요.',
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow:
                                            TextOverflow.visible,
                                        style: TextStyle(
                                          fontSize:
                                              isMobile ? 13 : 15,
                                          color:
                                              Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );

																if (compactHeader) {
																	return Column(
																		crossAxisAlignment:
																			CrossAxisAlignment.start,
																		mainAxisSize:
																			MainAxisSize.min,
																		children: [
																			headerText,

																			const SizedBox(height: 16),

																			OutlinedButton.icon(
																				onPressed: loadRecords,
																				icon: const Icon(
																					Icons.refresh_outlined,
																					size: 18,
																				),
																				label: const Text(
																					'새로고침',
																				),
																			),
																		],
																	);
																}

																return Row(
																	crossAxisAlignment:
																		CrossAxisAlignment.start,
																	children: [
																		Expanded(
																			child: headerText,
																		),

																		const SizedBox(width: 24),

																		OutlinedButton.icon(
																			onPressed: loadRecords,
																			icon: const Icon(
																				Icons.refresh_outlined,
																				size: 18,
																			),
																			label: const Text(
																				'새로고침',
																			),
																		),
																	],
																);
															},
														),

														const SizedBox(height: 28),
                              // ==================================================
                              // 여행 요약
                              // ==================================================

                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(
                                  isMobile ? 18 : 24,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                    22,
                                  ),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFE8EAE5,
                                    ),
                                  ),
                                ),
                                child: isMobile
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          _buildSummaryItem(
                                            icon: Icons
                                                .luggage_outlined,
                                            title:
                                                '총 여행',
                                            value:
                                                '${_records.length}회',
                                          ),
                                          const SizedBox(
                                            height: 16,
                                          ),
                                          _buildSummaryItem(
                                            icon: Icons
                                                .location_on_outlined,
                                            title:
                                                '최근 여행',
                                            value:
                                                _records
                                                        .isNotEmpty
                                                    ? _records
                                                        .first
                                                        .regionName
                                                    : '-',
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child:
                                                _buildSummaryItem(
                                              icon: Icons
                                                  .luggage_outlined,
                                              title:
                                                  '총 여행',
                                              value:
                                                  '${_records.length}회',
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 42,
                                            color:
                                                const Color(
                                              0xFFE5E7E2,
                                            ),
                                          ),
                                          Expanded(
                                            child:
                                                Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .only(
                                                left: 28,
                                              ),
                                              child:
                                                  _buildSummaryItem(
                                                icon: Icons
                                                    .location_on_outlined,
                                                title:
                                                    '최근 여행',
                                                value: _records
                                                        .isNotEmpty
                                                    ? _records
                                                        .first
                                                        .regionName
                                                    : '-',
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 42,
                                            color:
                                                const Color(
                                              0xFFE5E7E2,
                                            ),
                                          ),
                                          Expanded(
                                            child:
                                                Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .only(
                                                left: 28,
                                              ),
                                              child:
                                                  _buildSummaryItem(
                                                icon: Icons
                                                    .calendar_today_outlined,
                                                title:
                                                    '최근 여행일',
                                                value: _records
                                                        .isNotEmpty
                                                    ? _formatDate(
                                                        _records
                                                            .first
                                                            .startDate,
                                                      )
                                                    : '-',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),

                              const SizedBox(
                                height: 42,
                              ),

                              // ==================================================
                              // 기록 제목
                              // ==================================================

                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '여행 기록',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight:
                                            FontWeight.bold,
                                        letterSpacing:
                                            -0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_records.length}개의 기록',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors
                                          .grey
                                          .shade600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 18,
                              ),

                              // ==================================================
                              // 기록이 없는 경우
                              // ==================================================

                              if (_records.isEmpty)
                                _buildEmptyState()

                              // ==================================================
                              // 여행 기록 갤러리
                              // ==================================================

                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      _records.length,
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        isTablet
                                            ? 470
                                            : 390,
                                    mainAxisExtent:
                                        isMobile
                                            ? 425
                                            : 445,
                                    crossAxisSpacing:
                                        20,
                                    mainAxisSpacing:
                                        20,
                                  ),
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    return _buildRecordCard(
                                      index,
                                      _records[index],
                                    );
                                  },
                                ),

                              const SizedBox(
                                height: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ==============================================================
  // 요약 정보
  // ==============================================================

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2ED),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 21,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
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

    final bytes = await image.readAsBytes();

    final base64Image = base64Encode(bytes);

    if (!mounted) {
      return;
    }

    setState(() {
      widget.record.photoPaths.add(
        base64Image,
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
      recommendedRegion:
          widget.record.recommendedRegion,
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
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ======================================================
                // 대표 사진
                // ======================================================

                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // ------------------------------------------------
                      // 사진이 있으면 실제 사진 표시
                      // ------------------------------------------------

                      if (record.photoPaths.isNotEmpty)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(20),
                            child: Image.memory(
                              base64Decode(
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
                    borderRadius:
                        BorderRadius.circular(20),
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
                              i <
                                  record
                                      .visitedPlaces
                                      .length;
                              i++
                            )
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment:
                                          Alignment.center,
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .blue
                                            .shade50,
                                        shape:
                                            BoxShape.circle,
                                      ),
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
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        record
                                            .visitedPlaces[i],
                                        style:
                                            const TextStyle(
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
                    borderRadius:
                        BorderRadius.circular(20),
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
                                BorderRadius.circular(
                              15,
                            ),
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
                          onPressed: () =>
                              _saveRecord(),
                          child: const Text(
                            '기록 저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
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
        ),
      ),
    );
  }
}