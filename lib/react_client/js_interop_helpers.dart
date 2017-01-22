/// Utilities for reading/modifying dynamic keys on JavaScript objects
/// and converting Dart [Map]s to JavaScript objects.
@JS()
library react_client.js_interop_helpers;

import "package:js/js.dart";
import "package:js/js_util.dart" as js_util;

typedef dynamic _GetPropertyFn(jsObj, String key);
typedef dynamic _SetPropertyFn(jsObj, String key, value);

/// __Deprecated: use [js_util.getProperty] instead.
///
/// Returns the property at the given [_GetPropertyFn.key] on the
/// specified JavaScript object [_GetPropertyFn.jsObj]
///
/// Necessary because `external operator[]` isn't allowed on JS interop classes
/// (see: https://github.com/dart-lang/sdk/issues/25053).
///
/// __Defined in this package's React JS files.__
@Deprecated('4.0.0')
final _GetPropertyFn getProperty = js_util.getProperty;

/// __Deprecated: use [js_util.setProperty] instead.
///
/// Sets the property at the given [_SetPropertyFn.key] to [_SetPropertyFn.value]
/// on the specified JavaScript object [_SetPropertyFn.jsObj]
///
/// Necessary because `external operator[]=` isn't allowed on JS interop classes
/// (see: https://github.com/dart-lang/sdk/issues/25053).
///
/// __Defined in this package's React JS files.__
@Deprecated('4.0.0')
final _SetPropertyFn setProperty = (obj, key, value) {
  js_util.setProperty(obj, key, value);
  return value;
};


/// __Deprecated: use [js_util.newObject] instead.
///
/// An interop class for an anonymous JavaScript object, with no properties.
///
/// For use when dealing with dynamic properties via [getProperty]/[setProperty].
@JS()
@anonymous
@Deprecated('4.0.0')
class EmptyObject {
  external factory EmptyObject();
}

/// Returns [map] converted to a JavaScript object, similar to
/// `new JsObject.jsify` in `dart:js`.
///
/// Recursively converts nested [Map]s, and wraps [Function]s with [allowInterop].
///
/// TODO: deprecate and switch over to using [js_util.jsify]
dynamic jsify(Map map) {
  var jsMap = js_util.newObject();

  map.forEach((key, value) {
    if (value is Map) {
      value = jsify(value);
    } else if (value is Function) {
      value = allowInterop(value);
    }

    js_util.setProperty(jsMap, key, value);
  });

  return jsMap;
}
