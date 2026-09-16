import 'package:flutter/material.dart';

import '../../models/travel_plan.dart';
import '../../services/saved_place_storage.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({
    super.key,
  });

  @override
  State<SavedPlacesScreen> createState() =>
      _SavedPlacesScreenState();
}

class _SavedPlacesScreenState
    extends State<SavedPlacesScreen> {
  List<TravelSpot> places = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  // ============================================================
  // 저장한 장소 불러오기
  // ============================================================

  Future<void> _loadPlaces() async {
    try {
      final result =
          await SavedPlaceStorage.loadPlaces();

      if (!mounted) return;

      setState(() {
        places = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('저장한 장소 불러오기 실패: $e');

      if (!mounted) return;

      setState(() {
        places = [];
        isLoading = false;
      });
    }
  }

  // ============================================================
  // 저장한 장소 삭제
  // ============================================================

  Future<void> _removePlace(
    TravelSpot spot,
  ) async {
    try {
      await SavedPlaceStorage.removePlace(
        spot,
      );

      await _loadPlaces();
    } catch (e) {
      debugPrint('저장한 장소 삭제 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '장소를 삭제하지 못했어요.',
          ),
        ),
      );
    }
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
          '저장한 장소',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : places.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadPlaces,

                  child: ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      40,
                    ),

                    itemCount: places.length,

                    separatorBuilder:
                        (_, __) => Divider(
                      height: 1,
                      thickness: 0.7,
                      color: Colors.grey.shade100,
                      indent: 58,
                    ),

                    itemBuilder:
                        (context, index) {
                      final place =
                          places[index];

                      return _buildPlaceItem(
                        place,
                      );
                    },
                  ),
                ),
    );
  }

  // ============================================================
  // 장소 하나
  // ============================================================

  Widget _buildPlaceItem(
    TravelSpot place,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),

      onTap: () {
        // 추후 장소 상세 화면 연결
      },

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 2,
        ),

        child: Row(
          children: [
            // --------------------------------------------------
            // 장소 아이콘
            // --------------------------------------------------

            Container(
              width: 48,
              height: 48,

              decoration:
                  BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: Icon(
                Icons.place_outlined,
                size: 23,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(width: 13),

            // --------------------------------------------------
            // 장소 정보
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  if (place.category != null &&
                      place.category!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Text(
                      place.category!,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade500,
                      ),
                    ),
                  ],

                  if (place.address != null &&
                      place.address!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 3),

                    Text(
                      place.address!,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // --------------------------------------------------
            // 저장 해제
            // --------------------------------------------------

            IconButton(
              tooltip: '저장 해제',

              onPressed: () =>
                  _removePlace(place),

              icon: const Icon(
                Icons.favorite_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 저장한 장소 없음
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 76,
              height: 76,

              decoration:
                  BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(24),
              ),

              child: Icon(
                Icons.favorite_border_rounded,
                size: 38,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '저장한 장소가 없어요',

              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '마음에 드는 여행지를 저장하면\n'
              '여기에서 다시 볼 수 있어요.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}