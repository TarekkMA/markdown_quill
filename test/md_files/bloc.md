REMOVED HTML

---

A dart package that helps implement the [BLoC pattern](https://www.didierboelens.com/2018/08/reactive-programming---streams---bloc).

**Learn more at [bloclibrary.dev](https://bloclibrary.dev)!**

This package is built to work with:

- [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- [angular_bloc](https://pub.dev/packages/angular_bloc)
- [bloc_concurrency](https://pub.dev/packages/bloc_concurrency)
- [bloc_test](https://pub.dev/packages/bloc_test)
- [hydrated_bloc](https://pub.dev/packages/hydrated_bloc)
- [replay_bloc](https://pub.dev/packages/replay_bloc)

---

## Sponsors

Our top sponsors are shown below! [[Become a Sponsor](https://github.com/sponsors/felangel)]

REMOVED TABLE

---

## Overview

The goal of this package is to make it easy to implement the `BLoC` Design Pattern (Business Logic Component).

This design pattern helps to separate _presentation_ from _business logic_. Following the BLoC pattern facilitates testability and reusability. This package abstracts reactive aspects of the pattern allowing developers to focus on writing the business logic.

### Cubit

![Cubit Architecture](https://raw.githubusercontent.com/felangel/bloc/master/docs/assets/cubit_architecture_full.png)

A `Cubit` is class which extends `BlocBase` and can be extended to manage any type of state. `Cubit` requires an initial state which will be the state before `emit` has been called. The current state of a `cubit` can be accessed via the `state` getter and the state of the `cubit` can be updated by calling `emit` with a new `state`.

![Cubit Flow](https://raw.githubusercontent.com/felangel/bloc/master/docs/assets/cubit_flow.png)

State changes in cubit begin with predefined function calls which can use the `emit` method to output new states. `onChange` is called right before a state change occurs and contains the current and next state.

#### Creating a Cubit

```dart
/// A `CounterCubit` which manages an `int` as its state.
class CounterCubit extends Cubit<int> {
  /// The initial state of the `CounterCubit` is 0.
  CounterCubit() : super(0);
  /// When increment is called, the current state
  /// of the cubit is accessed via `state` and
  /// a new `state` is emitted via `emit`.
  void increment() => emit(state + 1);
}
```

#### Using a Cubit

```dart
void main() {
  /// Create a `CounterCubit` instance.
  final cubit = CounterCubit();
  /// Access the state of the `cubit` via `state`.
  print(cubit.state); // 0
  /// Interact with the `cubit` to trigger `state` changes.
  cubit.increment();
  /// Access the new `state`.
  print(cubit.state); // 1
  /// Close the `cubit` when it is no longer needed.
  cubit.close();
}
```

#### Observing a Cubit

`onChange` can be overridden to observe state changes for a single `cubit`.

`onError` can be overridden to observe errors for a single `cubit`.

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    print(change);
  }
  @override
  void onError(Object error, StackTrace stackTrace) {
    print('$error, $stackTrace');
    super.onError(error, stackTrace);
  }
}
```

`BlocObserver` can be used to observe all `cubits`.

```dart
class MyBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('onCreate -- ${bloc.runtimeType}');
  }
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('onChange -- ${bloc.runtimeType}, $change');
  }
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('onError -- ${bloc.runtimeType}, $error');
    super.onError(bloc, error, stackTrace);
  }
  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose -- ${bloc.runtimeType}');
  }
}
```

```dart
void main() {
  BlocOverrides.runZoned(
    () {
      // Use cubits...
    },
    blocObserver: MyBlocObserver(),
  );
}
```

### Bloc

![Bloc Architecture](https://raw.githubusercontent.com/felangel/bloc/master/docs/assets/bloc_architecture_full.png)

A `Bloc` is a more advanced class which relies on `events` to trigger `state` changes rather than functions. `Bloc` also extends `BlocBase` which means it has a similar public API as `Cubit`. However, rather than calling a `function` on a `Bloc` and directly emitting a new `state`, `Blocs` receive `events` and convert the incoming `events` into outgoing `states`.

![Bloc Flow](https://raw.githubusercontent.com/felangel/bloc/master/docs/assets/bloc_flow.png)

State changes in bloc begin when events are added which triggers `onEvent`. The events are then funnelled through an `EventTransformer`. By default, each event is processed concurrently but a custom `EventTransformer` can be provided to manipulate the incoming event stream. All registered `EventHandlers` for that event type are then invoked with the incoming event. Each `EventHandler` is responsible for emitting zero or more states in response to the event. Lastly, `onTransition` is called just before the state is updated and contains the current state, event, and next state.

#### Creating a Bloc

```dart
/// The events which `CounterBloc` will react to.
abstract class CounterEvent {}
/// Notifies bloc to increment state.
class Increment extends CounterEvent {}
/// A `CounterBloc` which handles converting `CounterEvent`s into `int`s.
class CounterBloc extends Bloc<CounterEvent, int> {
  /// The initial state of the `CounterBloc` is 0.
  CounterBloc() : super(0) {
    /// When an `Increment` event is added,
    /// the current `state` of the bloc is accessed via the `state` property
    /// and a new state is emitted via `emit`.
    on<Increment>((event, emit) => emit(state + 1));
  }
}
```

#### Using a Bloc

```dart
Future<void> main() async {
  /// Create a `CounterBloc` instance.
  final bloc = CounterBloc();
  /// Access the state of the `bloc` via `state`.
  print(bloc.state); // 0
  /// Interact with the `bloc` to trigger `state` changes.
  bloc.add(Increment());
  /// Wait for next iteration of the event-loop
  /// to ensure event has been processed.
  await Future.delayed(Duration.zero);
  /// Access the new `state`.
  print(bloc.state); // 1
  /// Close the `bloc` when it is no longer needed.
  await bloc.close();
}
```

#### Observing a Bloc

Since all `Blocs` extend `BlocBase` just like `Cubit`, `onChange` and `onError` can be overridden in a `Bloc` as well.

In addition, `Blocs` can also override `onEvent` and `onTransition`.

`onEvent` is called any time a new `event` is added to the `Bloc`.

`onTransition` is similar to `onChange`, however, it contains the `event` which triggered the state change in addition to the `currentState` and `nextState`.

```dart
abstract class CounterEvent {}
class Increment extends CounterEvent {}
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
  @override
  void onEvent(CounterEvent event) {
    super.onEvent(event);
    print(event);
  }
  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    print(change);
  }
  @override
  void onTransition(Transition<CounterEvent, int> transition) {
    super.onTransition(transition);
    print(transition);
  }
  @override
  void onError(Object error, StackTrace stackTrace) {
    print('$error, $stackTrace');
    super.onError(error, stackTrace);
  }
}
```

`BlocObserver` can be used to observe all `blocs` as well.

```dart
class MyBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('onCreate -- ${bloc.runtimeType}');
  }
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('onEvent -- ${bloc.runtimeType}, $event');
  }
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('onChange -- ${bloc.runtimeType}, $change');
  }
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('onTransition -- ${bloc.runtimeType}, $transition');
  }
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('onError -- ${bloc.runtimeType}, $error');
    super.onError(bloc, error, stackTrace);
  }
  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose -- ${bloc.runtimeType}');
  }
}
```

```dart
void main() {
  BlocOverrides.runZoned(
    () {
      // Use blocs...
    },
    blocObserver: MyBlocObserver(),
  );
}
```

## Dart Versions

- `Dart 2: >= 2.12`

## Examples

- [Counter](https://github.com/felangel/bloc/tree/master/packages/bloc/example) - an example of how to create a `CounterBloc` in a pure Dart app.

## Maintainers

- [Felix Angelov](https://github.com/felangel)
