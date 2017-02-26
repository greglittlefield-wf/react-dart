@JS()
library js_function_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:react/react_client/js_interop_helpers.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:test/test.dart';

void verifyJsFileLoaded(String filename) {
  var isLoaded = document.getElementsByTagName('script').any((script) {
    return Uri.parse((script as ScriptElement).src).pathSegments.last == filename;
  });

  if (!isLoaded) throw new Exception('$filename is not loaded');
}

void sharedJsFunctionTests() {
  group('JS functions:', () {
    group('getProperty', () {
      test('is function that does not throw upon initialization', () {
        expect(() => getProperty, const isInstanceOf<Function>());
      });

      test('gets the specified property on an object', () {
        var jsObj = new TestJsObject(foo: 'bar');
        expect(jsObj.foo, equals('bar'), reason: 'test setup sanity-check');

        expect(getProperty(jsObj, 'foo'), equals('bar'));
      });

      test('doesn\'t have any issues with null-checks in the result'
          ' (regression test for https://github.com/dart-lang/sdk/issues/28462)', () {
        var jsObj = new TestJsObject(foo: 'bar');
        expect(jsObj.foo, isNotNull, reason: 'test setup sanity-check');
        expect(jsObj.baz, isNull, reason: 'test setup sanity-check');

        // Use `== null` expression and not isNull matcher to ensure the same conditions
        // as in the bug are met
        expect(getProperty(jsObj, 'foo') == null, isFalse);
        expect(getProperty(jsObj, 'baz') == null, isTrue);
      });
    });

    group('setProperty', () {
      test('is function that does not throw upon initialization', () {
        expect(() => getProperty, const isInstanceOf<Function>());
      });

      test('sets the specified property on an object', () {
        var jsObj = new TestJsObject();
        expect(jsObj.foo, isNull, reason: 'test setup sanity-check');

        expect(setProperty(jsObj, 'foo', 'bar'), equals('bar'),
            reason: 'should return the result of the assignment expression');

        expect(jsObj.foo, equals('bar'));
      });
    });

    group('markChildValidated', () {
      test('is function that does not throw when called', () {
        expect(() => markChildValidated(newObject()), returnsNormally);
      });
    });

    group('createReactDartComponentClassConfig', () {
      test('is function that does not throw when called', () {
        expect(() => createReactDartComponentClassConfig(null, null), returnsNormally);
      });
    });
  });
}

@JS()
@anonymous
class TestJsObject {
  external factory TestJsObject({foo, baz});

  external get foo;
  external get baz;
}
