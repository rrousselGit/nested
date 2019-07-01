import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Nested extends Widget {
  const Nested({Key key, this.nested = const [], this.child})
      : assert(child != null),
        super(key: key);

  final List<SingleChildWidget> nested;
  final Widget child;

  @override
  NestedElement createElement() => NestedElement(this);
}

class NestedElement extends ComponentElement {
  NestedElement(Nested widget) : super(widget);

  @override
  Nested get widget => super.widget as Nested;

  @override
  Widget build() {
    var tree = _NestedHook(
      element: this,
      child: widget.child,
    );
    for (final provider in widget.nested.reversed) {
      tree = _NestedHook(
        element: this,
        child: provider,
        nextChild: tree,
      );
    }
    return tree;
  }
}

class _NestedHook extends StatelessWidget {
  const _NestedHook({Key key, this.element, this.nextChild, this.child})
      : assert(child != null),
        super(key: key);

  final NestedElement element;
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

void main() {
  testWidgets('can be with just the child', (tester) async {
    await tester.pumpWidget(const Nested(
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
  });
  testWidgets('something2', (tester) async {
    await tester.pumpWidget(const Nested(
      nested: [Foo(height: 42)],
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
    final box = find.byType(SizedBox).first.evaluate().first.widget as SizedBox;
    expect(box.height, equals(42));
  });

  testWidgets('standalone', (tester) async {
    await tester.pumpWidget(const Foo(
      height: 42,
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
    final box = find.byType(SizedBox).first.evaluate().first.widget as SizedBox;
    expect(box.height, equals(42));
  });
}

class Foo extends SingleChildStatelessWidget {
  const Foo({Key key, this.height, Widget child})
      : super(key: key, child: child);

  final double height;

  @override
  Widget build(BuildContext context, {Widget child}) {
    return SizedBox(height: height, child: child);
  }
}

class Adapter extends SingleChildStatelessWidget {
  const Adapter({Key key, this.builder}) : super(key: key);

  final Widget Function(BuildContext context, Widget child) builder;

  @override
  Widget build(BuildContext context, {Widget child}) {
    return builder(context, child);
  }
}

void foo() {
  Adapter(
    builder: (_, child) => Container(child: child),
  );
}
