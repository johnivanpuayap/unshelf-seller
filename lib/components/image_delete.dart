import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:unshelf_seller/utils/colors.dart';

class ImageWithDelete extends StatefulWidget {
  final Uint8List imageData;
  final VoidCallback onDelete;
  final double width;
  final double height;
  final EdgeInsets margin;

  ImageWithDelete({
    required this.imageData,
    required this.onDelete,
    this.width = 70.0,
    this.height = 70.0,
    this.margin = const EdgeInsets.only(right: 2.0),
  });

  @override
  State<ImageWithDelete> createState() => _ImageWithDeleteState();
}

class _ImageWithDeleteState extends State<ImageWithDelete> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDelete,
      child: MouseRegion(
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: Center(
          child: Stack(
            children: [
              Container(
                width: widget.width,
                height: widget.height,
                margin: widget.margin,
                child: Image.memory(
                  widget.imageData,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                ),
              ),
              if (_isHovering)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.delete, color: AppColors.error),
                        onPressed: widget.onDelete,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setHovering(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
  }
}
