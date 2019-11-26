[![Build Status](https://travis-ci.org/rrousselGit/nested.svg?branch=master)](https://travis-ci.org/rrousselGit/nested)
[![pub package](https://img.shields.io/pub/v/nested.svg)](https://pub.dartlang.org/packages/nested) [![codecov](https://codecov.io/gh/rrousselGit/nested/branch/master/graph/badge.svg)](https://codecov.io/gh/rrousselGit/nested)

A widget that simplifies the syntax for deeply nested wodget trees.

## Motivation

Widgets tends to get pretty nested rapidly.
It's not rare to see:

```dart
MyWidget(
  child: AnotherWidget(
    child: Again(
      child: AndAgain(
        child: Leaf(),
      )
    )
  )
)
```

That's not very ideal.

There's where `nested` propose a solution.
Using `nested`, it is possible to flatten thhe previous tree into:

```dart
Nested(
  children: [
    MyWidget(),
    AnotherWidget(),
    Again(),
    AndAgain(),
  ],
  child: Leaf(),
),
```

That's a lot more readable!

## Usage

`Nested` relies on a new kind of widget: [SingleChildWidget], which has two
concrete implementation:

- [SingleChildStatelessWidget]
- [SingleChildStatefulWidget]

These are [SingleChildWidget] variants of the original `Stateless`/`StatefulWidget`.

The difference between a widget and its single-child variant is that they have
a custom `build` method that takes an extra parameter.

As such, a `StatelessWidget` would be:

```dart
class MyWidget extends StatelessWidget {
  MyWidget({Key key, this.child}): super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SomethingWidget(child: child);
  }
}
```

Whereas a [SingleChildStatelessWidget] would be:

```dart
class MyWidget extends SingleChildStatelessWidget {
  MyWidget({Key key, Widget child}): super(key: key, child: child);

  @override
  Widget buildWithChild(BuildContext context, Widget child) {
    return SomethingWidget(child: child);
  }
}
```

This allows our new `MyWidget` to be used both with:

```dart
MyWidget(
  child: AnotherWidget(),
)
```

and to be placed inside `children` of [Nested] like so:

```dart
Nested(
  children: [
    MyWidget(),
    ...
  ],
  child: AnotherWidget(),
)
```

[singlechildwidget]: https://pub.dartlang.org/documentation/nexted/latest/nexted/SingleChildWidget-class.html
[singlechildstatelesswidget]: https://pub.dartlang.org/documentation/nexted/latest/nexted/SingleChildStatelessWidget-class.html
[singlechildstatefulwidget]: https://pub.dartlang.org/documentation/nexted/latest/nexted/SingleChildStatefulWidget-class.html
