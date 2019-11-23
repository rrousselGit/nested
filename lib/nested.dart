import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Nested extends SingleChildStatelessWidget {
  const Nested({Key key, this.nested = const [], Widget child})
      : super(key: key, child: child);

  final List<SingleChildWidget> nested;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    var tree = _NestedHook(
      child: child,
    );
    for (final child in nested.reversed) {
      tree = _NestedHook(
        child: child,
        nextChild: tree,
      );
    }
    return tree;
  }
}

class _NestedHook extends StatelessWidget {
  const _NestedHook({Key key, this.nextChild, this.child})
      : assert(child != null),
        super(key: key);

  final Widget child;
  final Widget nextChild;

  @override
  _NestedHookElement createElement() => _NestedHookElement(this);

  @override
  Widget build(BuildContext context) => child;
}

class _NestedHookElement extends StatelessElement {
  _NestedHookElement(_NestedHook widget) : super(widget);

  @override
  _NestedHook get widget => super.widget as _NestedHook;
}

abstract class SingleChildWidget implements Widget {
  @override
  _SingleChildWidgetElement createElement();
}

mixin _SingleChildWidgetElement on Element {
  Widget _widget;

  @override
  void mount(Element parent, dynamic newSlot) {
    if (parent is _NestedHookElement) {
      _widget = parent.widget.nextChild;
    }
    super.mount(parent, newSlot);
  }
}

abstract class SingleChildStatelessWidget extends StatelessWidget
    implements SingleChildWidget {
  const SingleChildStatelessWidget({Key key, Widget child})
      : _child = child,
        super(key: key);

  final Widget _child;

  @override
  Widget buildWithChild(BuildContext context, Widget child);

  @override
  Widget build(BuildContext context) {
    throw StateError('use buildWithChild instead');
  }

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
    return widget.buildWithChild(this, _widget ?? widget._child);
  }

  @override
  SingleChildStatelessWidget get widget =>
      super.widget as SingleChildStatelessWidget;
}

class NestedAdapter extends SingleChildStatelessWidget {
  const NestedAdapter({Key key, this.builder}) : super(key: key);

  final Widget Function(BuildContext context, Widget child) builder;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return builder(context, child);
  }
}
