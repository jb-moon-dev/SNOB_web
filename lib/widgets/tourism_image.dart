import 'package:flutter/material.dart';

import '../services/tourism_api_service.dart';

class TourismImage extends StatefulWidget {
  final String? contentId;
  final double? width;
  final double? height;
  final BoxFit fit;

  const TourismImage({
    super.key,
    required this.contentId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<TourismImage> createState() =>
      _TourismImageState();
}

class _TourismImageState
    extends State<TourismImage> {
  String? imageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadImage();
  }

  Future<void> _loadImage() async {
    final String? contentId =
        widget.contentId;

    if (contentId == null ||
        contentId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      return;
    }

    final List<String> images =
        await TourismApiService
            .getTourismImages(
      contentId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      imageUrl =
          images.isNotEmpty
              ? images.first
              : null;

      isLoading = false;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade100,
        child: const Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (imageUrl == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade100,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade400,
        ),
      );
    }

    return Image.network(
      imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder:
          (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.shade100,
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade400,
          ),
        );
      },
    );
  }
}