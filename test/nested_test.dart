import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TypeMatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:nested/nested.dart';

import 'common.dart';

void main() {
  testWidgets('insert widgets in natural order', (tester) async {
    await tester.pumpWidget(
      Nested(
        children: [
          MySizedBox(height: 0),
          MySizedBox(height: 1),
        ],
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('foo'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 0),
        isA<MySizedBox>().having((s) => s.height, 'height', 1),
      ]),
    );

    await tester.pumpWidget(
      Nested(
        children: [
          MySizedBox(height: 10),
          MySizedBox(height: 11),
        ],
        child: const Text('bar', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('bar'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 10),
        isA<MySizedBox>().having((s) => s.height, 'height', 11),
      ]),
    );
  });
  testWidgets('nested inside nested', (tester) async {
    await tester.pumpWidget(Nested(
      children: [
        MySizedBox(height: 0),
        Nested(
          children: [
            MySizedBox(height: 1),
            MySizedBox(height: 2),
          ],
        ),
        MySizedBox(height: 3),
      ],
      child: const Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 0),
        isA<MySizedBox>().having((s) => s.height, 'height', 1),
        isA<MySizedBox>().having((s) => s.height, 'height', 2),
        isA<MySizedBox>().having((s) => s.height, 'height', 3),
      ]),
    );

    await tester.pumpWidget(Nested(
      children: [
        MySizedBox(height: 10),
        Nested(
          children: [
            MySizedBox(height: 11),
            MySizedBox(height: 12),
          ],
        ),
        MySizedBox(height: 13),
      ],
      child: const Text('bar', textDirection: TextDirection.ltr),
    ));

    expect(find.text('bar'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((s) => s.height, 'height', 10),
        isA<MySizedBox>().having((s) => s.height, 'height', 11),
        isA<MySizedBox>().having((s) => s.height, 'height', 12),
        isA<MySizedBox>().having((s) => s.height, 'height', 13),
      ]),
    );
  });

  test('children is required', () {
    expect(
      () => Nested(
        children: null,
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
      throwsAssertionError,
    );
    expect(
      () => Nested(
        children: [],
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
      throwsAssertionError,
    );

    Nested(
      children: [MySizedBox()],
      child: const Text('foo', textDirection: TextDirection.ltr),
    );
  });

  testWidgets('no unnecessary rebuild #2', (tester) async {
    var buildCount = 0;
    final child = Nested(
      children: [
        MySizedBox(didBuild: (_, __) => buildCount++),
      ],
      child: Container(),
    );

    await tester.pumpWidget(child);

    expect(buildCount, equals(1));
    await tester.pumpWidget(child);

    expect(buildCount, equals(1));
  });

  testWidgets(
    'a node change rebuilds only that node',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);

      var buildCount2 = 0;
      final second = SingleChildBuilder(
        builder: (_, child) {
          buildCount2++;
          return child;
        },
      );

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
            SingleChildBuilder(
              builder: (_, __) =>
                  const Text('foo', textDirection: TextDirection.ltr),
            ),
          ],
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
            SingleChildBuilder(
              builder: (_, __) =>
                  const Text('bar', textDirection: TextDirection.ltr),
            )
          ],
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('bar'), findsOneWidget);
    },
  );
  testWidgets(
    'child change rebuilds last node',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);

      var buildCount2 = 0;
      final second = SingleChildBuilder(
        builder: (_, child) {
          buildCount2++;
          return child;
        },
      );

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [first, second],
          child: const Text('bar', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(2));
      expect(find.text('bar'), findsOneWidget);
    },
  );

  testWidgets(
    'if only one node, the previous and next nodes may not rebuild',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);
      var buildCount2 = 0;
      var buildCount3 = 0;
      final third = MySizedBox(didBuild: (_, __) => buildCount3++);

      final child = const Text('foo', textDirection: TextDirection.ltr);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            MySizedBox(
              didBuild: (_, __) => buildCount2++,
            ),
            third,
          ],
          child: child,
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(buildCount3, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            MySizedBox(
              didBuild: (_, __) => buildCount2++,
            ),
            third,
          ],
          child: child,
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(2));
      expect(buildCount3, equals(1));
      expect(find.text('foo'), findsOneWidget);
    },
  );

  testWidgets(
    'if child changes, rebuild the previous widget',
    (tester) async {
      var buildCount1 = 0;
      final first = MySizedBox(didBuild: (_, __) => buildCount1++);
      var buildCount2 = 0;
      final second = MySizedBox(didBuild: (_, __) => buildCount2++);

      await tester.pumpWidget(
        Nested(
          children: [first, second],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(1));
      expect(find.text('foo'), findsOneWidget);

      await tester.pumpWidget(
        Nested(
          children: [
            first,
            second,
          ],
          child: const Text('bar', textDirection: TextDirection.ltr),
        ),
      );

      expect(buildCount1, equals(1));
      expect(buildCount2, equals(2));
      expect(find.text('bar'), findsOneWidget);
    },
  );

  test('children cannot be null', () {
    expect(
      () => Nested(
        children: null,
        child: Container(),
      ),
      throwsAssertionError,
    );
  });
  testWidgets('last node receives child directly', (tester) async {
    Widget child;
    BuildContext context;

    await tester.pumpWidget(
      Nested(
        children: [
          SingleChildBuilder(
            builder: (ctx, c) {
              context = ctx;
              child = c;
              return Container();
            },
          )
        ],
        child: null,
      ),
    );

    expect(context, isNotNull);
    expect(child, isNull);

    final container = Container();

    await tester.pumpWidget(
      Nested(
        children: [
          SingleChildBuilder(
            builder: (ctx, c) {
              context = ctx;
              return child = c;
            },
          )
        ],
        child: container,
      ),
    );

    expect(context, isNotNull);
    expect(child, equals(container));
  });
  // TODO: assert keys order preserved (reorder unsupported)
  // TODO: nodes can be added optionally using [if] (_Hook takes a globalKey on the child's key)
  // TODO: a nested node moves to a new Nested
  // TODO: SingleChildStatefulWidget
  testWidgets('SingleChildBuilder can be used alone', (tester) async {
    Widget child;
    BuildContext context;
    var container = Container();

    await tester.pumpWidget(
      SingleChildBuilder(
        builder: (ctx, c) {
          context = ctx;
          child = c;
          return c;
        },
        child: container,
      ),
    );

    expect(child, equals(container));
    expect(context, equals(tester.element(find.byType(SingleChildBuilder))));

    container = Container();

    await tester.pumpWidget(
      SingleChildBuilder(
        builder: (ctx, c) {
          context = ctx;
          child = c;
          return c;
        },
        child: container,
      ),
    );

    expect(child, equals(container));
    expect(context, equals(tester.element(find.byType(SingleChildBuilder))));
  });
  testWidgets('SingleChildWidget can be used by itself', (tester) async {
    await tester.pumpWidget(
      MySizedBox(
        height: 42,
        child: const Text('foo', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('foo'), findsOneWidget);

    expect(
      find.byType(MySizedBox),
      matchesInOrder([
        isA<MySizedBox>().having((e) => e.height, 'height', equals(42)),
      ]),
    );
  });
}

class MySizedBox extends SingleChildStatelessWidget {
  MySizedBox({Key key, this.didBuild, this.height, Widget child})
      : super(key: key, child: child);

  final double height;

  final void Function(BuildContext context, Widget child) didBuild;

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    didBuild?.call(context, child);
    return child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('height', height));
  }
}
