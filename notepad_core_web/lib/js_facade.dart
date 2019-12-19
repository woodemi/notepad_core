@JS()
library js_facade;

import 'dart:async';
import 'dart:html' show EventTarget, EventListener;

import 'package:js/js.dart';

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

abstract class EventTargetDelegate {
  EventTarget get eventTarget;

  void addEventListener(String type, EventListener listener, [bool useCapture]) =>
    eventTarget.addEventListener(type, listener, useCapture);

  void removeEventListener(String type, EventListener listener, [bool useCapture]) =>
    eventTarget.removeEventListener(type, listener, useCapture);
}