import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Nested extends StatelessWidget implements SingleChildWidget {
  Nested({
    Key key,
    @required List<SingleChildWidget> children,
    Widget child,
  })  : assert(children != null),
        assert(children != null && children.isNotEmpty),
        _children = children,
        _child = child,
        super(key: key);

  final List<SingleChildWidget> _children;
  final Widget _child;

  @override
  Widget build(BuildContext context) {
    throw StateError('implemented internally');
  }

  @override
  _NestedElement createElement() => _NestedElement(this);
}

class _NestedElement extends StatelessElement with _SingleChildWidgetElement {
  _NestedElement(Nested widget) : super(widget);

  @override
  Nested get widget => super.widget as Nested;

  final nodes = <_NestedHookElement>{};

  @override
  Widget build() {
    _NestedHook nestedHook;
    var nextNode = _parent?.injectedChild ?? widget._child;

    for (final child in widget._children.reversed) {
      nextNode = nestedHook = _NestedHook(
        owner: this,
        wrappedWidget: child,
        injectedChild: nextNode,
      );
    }

    if (nestedHook != null) {
      // We manually update _NestedHookElement instead of letter widgets do their thing
      // because an item N may be constant but N+1 not. So, if we used widgets
      // then N+1 wouldn't rebuild because N didn't change
      for (final node in nodes) {
        node
          ..wrappedChild = nestedHook.wrappedWidget
          ..injectedChild = nestedHook.injectedChild;

        final next = nestedHook.injectedChild;
        if (next is _NestedHook) {
          nestedHook = next;
        } else {
          break;
        }
      }
    }

    return nextNode;
  }
}

class _NestedHook extends StatelessWidget {
  _NestedHook({
    this.injectedChild,
    @required this.wrappedWidget,
    @required this.owner,
  });

  final SingleChildWidget wrappedWidget;
  final Widget injectedChild;
  final _NestedElement owner;

  @override
  _NestedHookElement createElement() => _NestedHookElement(this);

  @override
  Widget build(BuildContext context) => throw StateError('handled internally');
}

class _NestedHookElement extends StatelessElement {
  _NestedHookElement(_NestedHook widget) : super(widget);

  @override
  _NestedHook get widget => super.widget as _NestedHook;

  Widget _injectedChild;
  Widget get injectedChild => _injectedChild;
  set injectedChild(Widget value) {
    if (value is _NestedHook && _injectedChild is _NestedHook) {
      // no need to rebuild the wrapped widget just for a _NestedHook.
      // The widget doesn't matter here, only its Element.
      return;
    }
    if (_injectedChild != value) {
      _injectedChild = value;
      visitChildren((e) => e.markNeedsBuild());
    }
  }

  SingleChildWidget _wrappedChild;
  SingleChildWidget get wrappedChild => _wrappedChild;
  set wrappedChild(SingleChildWidget value) {
    if (_wrappedChild != value) {
      _wrappedChild = value;
      markNeedsBuild();
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    widget.owner.nodes.add(this);
    _wrappedChild = widget.wrappedWidget;
    _injectedChild = widget.injectedChild;
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    widget.owner.nodes.remove(this);
    super.unmount();
  }

  @override
  Widget build() {
    return wrappedChild;
  }
}

/// A [Widget] that takes a single descendant.
///
/// As opposed to [ProxyWidget], it may have a "build" method.
///
/// See also:
/// - [SingleChildStatelessWidget]
/// - [SingleChildStatefulWidget]
abstract class SingleChildWidget implements Widget {
  @override
  _SingleChildWidgetElement createElement();
}

mixin _SingleChildWidgetElement on Element {
  _NestedHookElement _parent;

  @override
  void mount(Element parent, dynamic newSlot) {
    if (parent is _NestedHookElement) {
      _parent = parent;
    }
    super.mount(parent, newSlot);
  }
}

/// A [StatelessWidget] that implements [SingleChildWidget] and is therefore
/// compatible with [Nested].
///
/// Its [build] method must **not** be overriden. Instead use [buildWithChild].
abstract class SingleChildStatelessWidget extends StatelessWidget
    implements SingleChildWidget {
  /// Creates a widget that has exactly one child widget.
  const SingleChildStatelessWidget({Key key, Widget child})
      : _child = child,
        super(key: key);

  final Widget _child;

  /// A [build] method that receives an extra `child` parameter.
  ///
  /// This method may be called with a `child` different from the parameter
  /// passed to the constructor of [SingleChildStatelessWidget].
  /// It may also be called again with a different `child`, without this widget
  /// being recreated.
  Widget buildWithChild(BuildContext context, Widget child);

  @override
  Widget build(BuildContext context) => buildWithChild(context, _child);

  @override
  _SingleChildStatelessElement createElement() =>
      _SingleChildStatelessElement(this);
}

class _SingleChildStatelessElement extends StatelessElement
    with _SingleChildWidgetElement {
  _SingleChildStatelessElement(SingleChildStatelessWidget widget)
      : super(widget);

  @override
  Widget build() {
    if (_parent != null) {
      return widget.buildWithChild(this, _parent.injectedChild);
    }
    return super.build();
  }

  @override
  SingleChildStatelessWidget get widget =>
      super.widget as SingleChildStatelessWidget;
}

/// A [SingleChildWidget] that delegates its implementation to a callback.
///
/// It works like [Builder], but is compatible with [Nested].
class SingleChildBuilder extends SingleChildStatelessWidget {
  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const SingleChildBuilder({Key key, @required this.builder, Widget child})
      : assert(builder != null),
        super(key: key, child: child);

  /// Called to obtain the child widget.
  ///
  /// The `child` parameter may be different from the one parameter passed to
  /// the constructor of [SingleChildBuilder].
  final Widget Function(BuildContext context, Widget child) builder;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return builder(context, child);
  }
}
