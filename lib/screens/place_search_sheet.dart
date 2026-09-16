import 'package:flutter/material.dart';

import '../../../services/kakao_local_service.dart';

class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({
    super.key,
  });

  @override
  State<PlaceSearchSheet> createState() =>
      _PlaceSearchSheetState();
}

class _PlaceSearchSheetState
    extends State<PlaceSearchSheet> {
  final _controller =
      TextEditingController();

  final _service =
      KakaoLocalService();

  final _focusNode =
      FocusNode();

  List<KakaoPlace> _results = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      setState(() {});
    });
  }

  Future<void> _search() async {
    final query =
        _controller.text.trim();

    if (query.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results =
          await _service.searchPlaces(
        query,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
        _loading = false;
      });

      if (results.isEmpty) {
        setState(() {
          _error =
              '검색 결과가 없어요.\n'
              '장소명을 조금 다르게 입력해보세요.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            '장소 검색에 실패했어요.\n'
            'Kakao API 설정을 확인해주세요.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.only(
          top: 8,
        ),
        child: Column(
          children: [
            // --------------------------------------------------
            // Header
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                14,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '장소 검색',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon:
                        const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // Search bar
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: TextField(
                controller:
                    _controller,
                focusNode:
                    _focusNode,
                autofocus: true,
                textInputAction:
                    TextInputAction.search,
                onSubmitted: (_) =>
                    _search(),
                decoration:
                    InputDecoration(
                  hintText:
                      '장소명을 검색하세요',
                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                      _controller
                              .text
                              .isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _controller
                                    .clear();

                                setState(() {
                                  _results =
                                      [];
                                  _error =
                                      null;
                                });

                                _focusNode
                                    .requestFocus();
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .clear,
                              ),
                            ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                  filled: true,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // --------------------------------------------------
            // Search button
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _search,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.search,
                        ),
                  label: Text(
                    _loading
                        ? '검색 중...'
                        : '장소 검색',
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // Error
            // --------------------------------------------------

            if (_error != null)
              Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  _error!,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors
                        .grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),

            // --------------------------------------------------
            // Results
            // --------------------------------------------------

            Expanded(
              child:
                  ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  30,
                ),
                itemCount:
                    _results.length,
                separatorBuilder:
                    (_, __) =>
                        const SizedBox(
                  height: 8,
                ),
                itemBuilder:
                    (context, index) {
                  final place =
                      _results[index];

                  return _PlaceResultTile(
                    place: place,
                    onTap: () {
                      Navigator.pop(
                        context,
                        place,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceResultTile
    extends StatelessWidget {
  final KakaoPlace place;
  final VoidCallback onTap;

  const _PlaceResultTile({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(
          16,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .primary
                    .withOpacity(
                      0.09,
                    ),
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),
              child: Icon(
                Icons
                    .location_on_outlined,
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (place
                          .categoryName !=
                      null) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      place
                          .categoryName!,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    place.displayAddress,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey.shade600,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .gps_fixed,
                        size: 12,
                        color: Colors
                            .grey.shade500,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        '${place.latitude.toStringAsFixed(5)}, '
                        '${place.longitude.toStringAsFixed(5)}',
                        style:
                            TextStyle(
                          fontSize: 10,
                          color: Colors
                              .grey
                              .shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            const Icon(
              Icons
                  .chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}