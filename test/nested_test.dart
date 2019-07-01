import 'package:flutter/material.dart' hide TypeMatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:nested/nested.dart';

void main() {
  testWidgets('can be with just the child', (tester) async {
    await tester.pumpWidget(const Nested(
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
  });
  testWidgets('something2', (tester) async {
    await tester.pumpWidget(const Nested(
      nested: [
        Foo(height: 42),
        Foo(height: 10),
      ],
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
    final box = find.byType(SizedBox).evaluate().toList();
    expect(box.length, equals(2));
    expect(
      box[0].widget,
      const TypeMatcher<SizedBox>().having((s) => s.height, 'height', 42),
    );
    expect(
      box[1].widget,
      const TypeMatcher<SizedBox>().having((s) => s.height, 'height', 10),
    );
  });

  testWidgets('nested inside nested', (tester) async {
    await tester.pumpWidget(const Nested(
      nested: [
        Foo(height: 0),
        Nested(
          nested: [
            Foo(height: 1),
            Foo(height: 2),
          ],
        ),
        Foo(height: 3),
      ],
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
    final box = find.byType(SizedBox).evaluate().toList();
    expect(box.length, equals(4));

    for (var i = 0; i < 4; i++) {
      expect(
        box[i].widget,
        const TypeMatcher<SizedBox>().having((s) => s.height, 'height', i),
      );
    }
  });

  testWidgets('no unnecessary rebuild', (tester) async {
    var buildCount = 0;
    await tester.pumpWidget(Nested(nested: [
      Foo(didBuild: (_, __) => buildCount++),
    ], child: Container()));

    expect(buildCount, equals(1));

    await tester.pumpWidget(Nested(nested: [
      Foo(didBuild: (_, __) => buildCount++),
    ], child: Container()));

    expect(buildCount, equals(2));
  });

  testWidgets('no unnecessary rebuild #2', (tester) async {
    var buildCount = 0;
    final child = Nested(
      nested: [
        Foo(didBuild: (_, __) => buildCount++),
      ],
      child: Container(),
    );

    await tester.pumpWidget(child);

    expect(buildCount, equals(1));
    await tester.pumpWidget(child);

    expect(buildCount, equals(1));
  });

  testWidgets('no unnecessary rebuild #3', (tester) async {
    var rootBuildCount = 0;
    var secondBuildCount = 0;

    final root = Foo(didBuild: (_, __) => rootBuildCount++);
    final second = Foo(didBuild: (_, __) => secondBuildCount++);

    await tester.pumpWidget(Nested(
      nested: [
        root,
        second,
      ],
      child: Container(),
    ));

    await tester.pumpWidget(Nested(
      nested: [
        root,
        second,
      ],
      child: Container(),
    ));

    expect(
      rootBuildCount,
      equals(1),
      reason: '`second` never changed',
    );
    expect(
      secondBuildCount,
      equals(2),
      reason: '`child` rebuilt',
    );
  }, skip: true);

  testWidgets(
    'rebuilding with more nested without updating previous nested rebuilds latest previous nested',
    (tester) async {
      await tester.pumpWidget(const Nested(
        nested: [
          Foo(height: 0),
        ],
        child: Text('foo', textDirection: TextDirection.ltr),
      ));

      await tester.pumpWidget(const Nested(
        nested: [
          Foo(height: 0),
          Foo(height: 1),
        ],
        child: Text('foo', textDirection: TextDirection.ltr),
      ));

      expect(find.text('foo'), findsOneWidget);
      final box = find.byType(SizedBox).evaluate().toList();
      expect(box.length, equals(2));

      for (var i = 0; i < 2; i++) {
        expect(
          box[i].widget,
          const TypeMatcher<SizedBox>().having((s) => s.height, 'height', i),
        );
      }
    },
    skip: true,
  );

  testWidgets(
    "moving a SingleChildWidget don't destroy state",
    (tester) async {},
    skip: true,
  );

  testWidgets('SingleChildWidget can be used by itself', (tester) async {
    await tester.pumpWidget(const Foo(
      height: 42,
      child: Text('foo', textDirection: TextDirection.ltr),
    ));

    expect(find.text('foo'), findsOneWidget);
    final box = find.byType(SizedBox).evaluate().single.widget;
    expect(
      box,
      const TypeMatcher<SizedBox>().having((s) => s.height, 'height', 42),
    );
  });
}

class Foo extends SingleChildStatelessWidget {
  const Foo({Key key, this.didBuild, this.height, Widget child})
      : super(key: key, child: child);

  final double height;

  final void Function(BuildContext context, Widget child) didBuild;

  @override
  Widget build(BuildContext context, {Widget child}) {
    didBuild?.call(context, child);
    return SizedBox(height: height, child: child);
  }
}
