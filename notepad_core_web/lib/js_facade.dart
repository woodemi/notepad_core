@JS()
library js_facade;

import 'dart:async';
import 'dart:html' show EventTarget, EventListener;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS()
class Promise<T> {
  external Promise(void executor(void resolve(T result), Function reject));

  external Promise then(void onFulfilled(T result), [Function onRejected]);
}

Future<T> promiseToFuture<T>(Promise<T> promise) {
  final c = Completer<T>();
  promise.then(allowInterop(c.complete), allowInterop(c.completeError));
  return c.future;
}

abstract class Delegate<T> {
  final T _delegate;

  T get delegate => _delegate;

  Delegate(this._delegate);

  T getProperty<T>(dynamic name) => js_util.getProperty(_delegate, name);

  T callMethod<T>(String method, List args) => js_util.callMethod(_delegate, method, args);
}

abstract class EventTargetDelegate extends Delegate<EventTarget> {
  EventTargetDelegate(EventTarget delegate) : super(delegate);

  void addEventListener(String type, EventListener listener, [bool useCapture]) =>
    delegate.addEventListener(type, listener, useCapture);

  void removeEventListener(String type, EventListener listener, [bool useCapture]) =>
    delegate.removeEventListener(type, listener, useCapture);
}