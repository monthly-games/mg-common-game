import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 지연 로딩 전략
enum LazyLoadStrategy {
  /// 즉시 로드
  immediate,

  /// 가시 영역에 진입 시 로드
  onVisible,

  /// 가까워질 때 로드 (미리 로드)
  onApproaching,

  /// 수동 로드
  manual,
}

/// 지연 로딩 위젯
class LazyLoadWidget extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final Widget? placeholder;
  final LazyLoadStrategy strategy;
  final double triggerThreshold;
  final Duration delay;

  const LazyLoadWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.strategy = LazyLoadStrategy.onVisible,
    this.triggerThreshold = 500,
    this.delay = Duration.zero,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.strategy == LazyLoadStrategy.immediate) {
      _loadWidget();
    }
  }

  void _loadWidget() {
    if (_isLoading || _isLoaded) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isLoaded) return false;

        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return false;

          final position = renderBox.localToGlobal(Offset.zero).dy;
          final viewportHeight = metrics.viewportDimension;
          final distance = position - viewportHeight;

          if (widget.strategy == LazyLoadStrategy.onVisible && distance <= 0) {
            _loadWidget();
          } else if (widget.strategy == LazyLoadStrategy.onApproaching &&
              distance <= widget.triggerThreshold) {
            _loadWidget();
          }
        }

        return false;
      },
      child: _isLoaded
          ? widget.builder(context)
          : (widget.placeholder ?? _buildPlaceholder()),
    );
  }
}

Widget _buildPlaceholder() {
  return Container(
    height: 200,
    color: Colors.grey[200],
    child: const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

/// Lazy ListView
class LazyListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loadItems;
  final Widget Function(BuildContext, T) itemBuilder;
  final int pageSize;
  final Widget? loadingIndicator;
  final Widget? errorWidget;

  const LazyListView({
    super.key,
    required this.loadItems,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingIndicator,
    this.errorWidget,
  });

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.loadItems(_offset, widget.pageSize);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _offset += newItems.length;
          _hasMore = newItems.length == widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return widget.itemBuilder(context, _items[index]);
        }

        // 마지막 항목에 도달하면 더 로드
        if (_hasMore && !_isLoading) {
          _loadMoreItems();
        }

        if (_isLoading) {
          return widget.loadingIndicator ??
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
        }

        if (_hasError) {
          return widget.errorWidget ??
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('로드 실패'),
                    ElevatedButton(
                      onPressed: _loadMoreItems,
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Lazy GridView
class LazyGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int offset, int limit) loadItems;
  final Widget Function(BuildContext, T) itemBuilder;
  final int pageSize;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Widget? loadingIndicator;
  final Widget? errorWidget;

  const LazyGridView({
    super.key,
    required this.loadItems,
    required this.itemBuilder,
    this.pageSize = 20,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1.0,
    this.loadingIndicator,
    this.errorWidget,
  });

  @override
  State<LazyGridView<T>> createState() => _LazyGridViewState<T>();
}

class _LazyGridViewState<T> extends State<LazyGridView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.loadItems(_offset, widget.pageSize);

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _offset += newItems.length;
          _hasMore = newItems.length == widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return widget.itemBuilder(context, _items[index]);
        }

        // 마지막 항목에 도달하면 더 로드
        if (_hasMore && !_isLoading) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _loadMoreItems();
          });
        }

        if (_isLoading) {
          return widget.loadingIndicator ??
              const Center(child: CircularProgressIndicator());
        }

        if (_hasError) {
          return widget.errorWidget ??
              Center(
                child: ElevatedButton(
                  onPressed: _loadMoreItems,
                  child: const Text('재시도'),
                ),
              );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// 이미지 지연 로더
class LazyImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeDuration;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage>
    with SingleTickerProviderStateMixin {
  bool _isLoaded = false;
  bool _hasError = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // 이미지 로드 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
        _controller.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? const Icon(Icons.error);
    }

    if (!_isLoaded) {
      return widget.placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    return FadeTransition(
      opacity: _animation,
      child: Image.network(
        widget.imageUrl,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? const Icon(Icons.error);
        },
      ),
    );
  }
}

/// 지연 로딩 빌더
class LazyBuilder<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool autoLoad;

  const LazyBuilder({
    super.key,
    required this.loader,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.autoLoad = true,
  });

  @override
  State<LazyBuilder<T>> createState() => _LazyBuilderState<T>();
}

class _LazyBuilderState<T> extends State<LazyBuilder<T>> {
  T? _data;
  Object? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      load();
    }
  }

  Future<void> load() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.loader();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ??
          Center(
            child: Column(
              children: [
                Text('Error: $_error'),
                ElevatedButton(
                  onPressed: load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_data == null) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    return widget.builder(context, _data!);
  }
}
