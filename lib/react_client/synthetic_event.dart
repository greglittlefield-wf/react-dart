import 'dart:html';
import 'package:js/js.dart';

import 'package:react/react.dart' as react;

@JS()
class SyntheticEvent implements react.SyntheticEvent {
  external bool get bubbles;
  external bool get cancelable;
  external get currentTarget;
  external bool get defaultPrevented;
  external num get eventPhase;
  external bool get isTrusted;
  external get nativeEvent;
  external get target;
  external num get timeStamp;
  external String get type;

  external void stopPropagation();
  external void preventDefault();
}

@JS()
class SyntheticClipboardEvent extends SyntheticEvent implements react.SyntheticClipboardEvent {
  external get clipboardData;
}

@JS()
class SyntheticKeyboardEvent extends SyntheticEvent implements react.SyntheticKeyboardEvent {
  external bool get altKey;
  external String get char;
  external bool get ctrlKey;
  external String get locale;
  external num get location;
  external String get key;
  external bool get metaKey;
  external bool get repeat;
  external bool get shiftKey;
  external num get keyCode;
  external num get charCode;
}

@JS()
class SyntheticFocusEvent extends SyntheticEvent implements react.SyntheticFocusEvent {
  external EventTarget get relatedTarget;
}

@JS()
class SyntheticFormEvent extends SyntheticEvent  implements react.SyntheticFormEvent {}

@JS()
class SyntheticDataTransfer implements react.SyntheticDataTransfer {
  external String get dropEffect;
  external String get effectAllowed;
  external List<File> get files;
  external List<String> get types;
}

@JS()
class SyntheticMouseEvent extends SyntheticEvent implements react.SyntheticMouseEvent {
  external bool get altKey;
  external num get button;
  external num get buttons;
  external num get clientX;
  external num get clientY;
  external bool get ctrlKey;
  external SyntheticDataTransfer get dataTransfer;
  external bool get metaKey;
  external num get pageX;
  external num get pageY;
  external EventTarget get relatedTarget;
  external num get screenX;
  external num get screenY;
  external bool get shiftKey;
}

@JS()
class SyntheticTouchEvent extends SyntheticEvent implements react.SyntheticTouchEvent {
  external bool get altKey;
  external TouchList get changedTouches;
  external bool get ctrlKey;
  external bool get metaKey;
  external bool get shiftKey;
  external TouchList get targetTouches;
  external TouchList get touches;
}

@JS()
class SyntheticUIEvent extends SyntheticEvent implements react.SyntheticUIEvent {
  external num get detail;
  external get view;
}

@JS()
class SyntheticWheelEvent extends SyntheticEvent implements react.SyntheticWheelEvent {
  external num get deltaX;
  external num get deltaMode;
  external num get deltaY;
  external num get deltaZ;
}
