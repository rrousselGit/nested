import 'package:flutter/widgets.dart';

class Nested extends SingleChildStatelessWidget {
  const Nested({Key key, this.nested = const [], Widget child})
      : super(key: key, child: child);

  final List<SingleChildWidget> nested;

  @override
  Widget build(BuildContext context, {Widget child}) {
    var tree = _NestedHook(
      child: child,
    );
    for (final provider in nested.reversed) {
      tree = _NestedHook(
        child: provider,
        nextChild: tree,
      );
    }
    return tree;
  }

  @override
  _NestedElement createElement() => _NestedElement(this);
}

// currently useless
// but that's where the failing tests should be fixed
class _NestedElement extends SingleChildStatelessElement {
  _NestedElement(Nested widget) : super(widget);

  @override
  Nested get widget => super.widget as Nested;
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
  SingleChildWidgetElement createElement();
}

mixin SingleChildWidgetElement on Element {
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
  Widget build(BuildContext context, {Widget child});

  @override
  SingleChildStatelessElement createElement() =>
      SingleChildStatelessElement(this);
}

class SingleChildStatelessElement extends StatelessElement
    with SingleChildWidgetElement {
  SingleChildStatelessElement(SingleChildStatelessWidget widget)
      : super(widget);

  @override
  Widget build() {
    return widget.build(this, child: _widget ?? widget._child);
  }

  @override
  SingleChildStatelessWidget get widget =>
      super.widget as SingleChildStatelessWidget;
}

class Adapter extends SingleChildStatelessWidget {
  const Adapter({Key key, this.builder}) : super(key: key);

  final Widget Function(BuildContext context, Widget child) builder;

  @override
  Widget build(BuildContext context, {Widget child}) {
    return builder(context, child);
  }
}
