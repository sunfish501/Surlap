import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef MonthItemBuilder =
    Widget Function(BuildContext context, DateTime month);

/// A lazy, vertically continuous list of calendar months.
///
/// Two sliver lists grow away from a center anchor, so earlier and later
/// months are both available without a large initial scroll offset. Native
/// scroll physics are intentionally retained: there is no paging or snap.
class ContinuousMonthList extends StatefulWidget {
  const ContinuousMonthList({
    super.key,
    required this.targetMonth,
    required this.itemExtent,
    required this.itemBuilder,
    required this.onVisibleMonthChanged,
  });

  static const int monthsPerDirection = 12000;

  final DateTime targetMonth;
  final double itemExtent;
  final MonthItemBuilder itemBuilder;
  final ValueChanged<DateTime> onVisibleMonthChanged;

  @override
  State<ContinuousMonthList> createState() => _ContinuousMonthListState();
}

class _ContinuousMonthListState extends State<ContinuousMonthList> {
  final _centerKey = GlobalKey();
  late final DateTime _anchorMonth;
  late final ScrollController _controller;
  int _visibleOffset = 0;
  int _reportedOffset = 0;

  @override
  void initState() {
    super.initState();
    _anchorMonth = _monthOnly(widget.targetMonth);
    // The anchor already represents the currently selected month. Restoring a
    // previous pixel offset on top of a new anchor shifts the list twice and
    // also forces unnecessary layout work when returning to this tab.
    _controller = ScrollController(keepScrollOffset: false);
  }

  @override
  void didUpdateWidget(covariant ContinuousMonthList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetOffset = _offsetForMonth(widget.targetMonth);
    final extentChanged = oldWidget.itemExtent != widget.itemExtent;
    if (!extentChanged && targetOffset == _visibleOffset) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final targetPixels = targetOffset * widget.itemExtent;
      final distance = (targetPixels - _controller.offset).abs();
      if (extentChanged || distance > widget.itemExtent * 3) {
        _controller.jumpTo(targetPixels);
        _setVisibleOffset(targetOffset, report: false);
        _reportedOffset = targetOffset;
        return;
      }
      _controller.animateTo(
        targetPixels,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final nextOffset = (notification.metrics.pixels / widget.itemExtent)
        .floor()
        .clamp(
          -ContinuousMonthList.monthsPerDirection,
          ContinuousMonthList.monthsPerDirection,
        );
    _setVisibleOffset(nextOffset, report: false);

    if (notification is ScrollEndNotification ||
        notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle) {
      _setVisibleOffset(nextOffset, report: true);
    }
    return false;
  }

  void _setVisibleOffset(int offset, {required bool report}) {
    _visibleOffset = offset;
    if (!report || offset == _reportedOffset) return;
    _reportedOffset = offset;
    widget.onVisibleMonthChanged(_monthForOffset(offset));
  }

  int _offsetForMonth(DateTime month) {
    final normalized = _monthOnly(month);
    final delta =
        (normalized.year - _anchorMonth.year) * 12 +
        normalized.month -
        _anchorMonth.month;
    return delta.clamp(
      -ContinuousMonthList.monthsPerDirection,
      ContinuousMonthList.monthsPerDirection,
    );
  }

  DateTime _monthForOffset(int offset) =>
      DateTime(_anchorMonth.year, _anchorMonth.month + offset);

  DateTime _monthOnly(DateTime date) => DateTime(date.year, date.month);

  Widget _buildMonth(BuildContext context, int offset) {
    final month = _monthForOffset(offset);
    return RepaintBoundary(
      key: ValueKey<String>('month-section-${month.year}-${month.month}'),
      child: widget.itemBuilder(context, month),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        controller: _controller,
        center: _centerKey,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: ScrollCacheExtent.pixels(widget.itemExtent * 0.25),
        slivers: [
          SliverFixedExtentList(
            itemExtent: widget.itemExtent,
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMonth(context, -index - 1),
              childCount: ContinuousMonthList.monthsPerDirection,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              addSemanticIndexes: false,
            ),
          ),
          SliverFixedExtentList(
            key: _centerKey,
            itemExtent: widget.itemExtent,
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMonth(context, index),
              childCount: ContinuousMonthList.monthsPerDirection + 1,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              addSemanticIndexes: false,
            ),
          ),
        ],
      ),
    );
  }
}
