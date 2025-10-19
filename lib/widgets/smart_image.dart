import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

/// A smart image widget that handles both base64 data URLs and network URLs
class SmartImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const SmartImage({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Default placeholder
    final defaultPlaceholder = Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Default error widget - use Midwest logo
    final defaultErrorWidget = Container(
      color: Colors.grey[200],
      child: Image.asset(
        'lib/midwest_logo.jpg',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.broken_image,
            size: 100,
            color: Colors.grey,
          );
        },
      ),
    );

    // No image URL provided - show Midwest logo
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Container(
          color: Colors.grey[200],
          child: Image.asset(
            'lib/midwest_logo.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 100,
                color: Colors.grey,
              );
            },
          ),
        ),
      );
    }

    // Handle base64 data URLs
    if (imageUrl!.startsWith('data:')) {
      try {
        // Extract base64 data from data URL
        final base64String = imageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return SizedBox(
          width: width,
          height: height,
          child: Image.memory(
            bytes,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? Container(
                color: Colors.grey[200],
                child: Image.asset(
                  'lib/midwest_logo.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
              );
            },
          ),
        );
      } catch (e) {
        return SizedBox(
          width: width,
          height: height,
          child: errorWidget ?? Container(
            color: Colors.grey[200],
            child: Image.asset(
              'lib/midwest_logo.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.grey,
                );
              },
            ),
          ),
        );
      }
    }

    // Handle network URLs with caching
    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (context, url) => placeholder ?? defaultPlaceholder,
        errorWidget: (context, url, error) => errorWidget ?? Container(
          color: Colors.grey[200],
          child: Image.asset(
            'lib/midwest_logo.jpg',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 100,
                color: Colors.grey,
              );
            },
          ),
        ),
      ),
    );
  }
}
