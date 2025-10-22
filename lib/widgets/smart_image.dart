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
    // Debug: Print the image URL being processed
    print('SmartImage: Processing imageUrl: $imageUrl');
    
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
      print('SmartImage: Processing base64 data URL');
      try {
        // Extract the base64 data and mime type
        final url = imageUrl!; // Create a local non-null variable
        final parts = url.split(',');
        if (parts.length == 2) {
          final mimeType = parts[0].split(':')[1].split(';')[0];
          final base64Data = parts[1];
          
          // Decode base64 to bytes
          final bytes = base64.decode(base64Data);
          
          return SizedBox(
            width: width,
            height: height,
            child: Image.memory(
              bytes,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                print('SmartImage: Error displaying base64 image: $error');
                return errorWidget ?? defaultErrorWidget;
              },
            ),
          );
        }
      } catch (e) {
        print('SmartImage: Error processing base64 data URL: $e');
        return errorWidget ?? defaultErrorWidget;
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