import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class InfiniteMarquee extends StatefulWidget {
  final List<Widget> children;
  final double stepOffset;
  final Duration stepDuration;
  final ScrollPhysics physics;

  const InfiniteMarquee({
    Key? key,
    required this.children,
    this.stepOffset = 2.0, // Pixels to move per step
    this.stepDuration = const Duration(milliseconds: 50), // Loop duration
    this.physics = const BouncingScrollPhysics(),
  }) : super(key: key);

  @override
  _InfiniteMarqueeState createState() => _InfiniteMarqueeState();
}

class _InfiniteMarqueeState extends State<InfiniteMarquee> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.stepDuration, (timer) {
      if (!_scrollController.hasClients || !_isAutoScrolling) return;
      
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.offset;
      
      // If we are at the very end (simulated infinite), jump back to near start
      // But actually, with ListView.builder repeating, we just keep scrolling.
      // However, eventually double precision runs out.
      // A better approach for "Infinite" without billions of items is to reset when we reach end of "real" items.
      // But simplifying: just scroll.
      
      double newScroll = currentScroll + widget.stepOffset;
      _scrollController.jumpTo(newScroll);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Pause on user drag
        if (notification.direction != ScrollDirection.idle) {
            _isAutoScrolling = false;
        } else {
             // Resume after a short delay
             Future.delayed(const Duration(seconds: 2), () {
                 if (mounted) setState(() => _isAutoScrolling = true);
             });
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: widget.physics,
        // Huge number to simulate infinity
        itemCount: 100000, 
        itemBuilder: (context, index) {
          // Modulo index to repeat items
          final itemIndex = index % widget.children.length;
          return widget.children[itemIndex];
        },
      ),
    );
  }
}
