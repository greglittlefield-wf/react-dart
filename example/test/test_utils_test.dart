import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'dart:js';

import "package:react/react_test_utils.dart";

class _CustomComponent extends react.Component {
  render() {
    return react.div({});
  }
}
ReactComponentFactory customComponent = react.registerComponent(() => new _CustomComponent());

void main() {
  setClientConfiguration();

  useHtmlEnhancedConfiguration();

  group("Component instance checking", () {
    JsObject instance;

    setUp(() {
      instance = customComponent({});
    });

    test("identifies React elements", () {
      expect(ReactTestUtils.isElement(instance), isTrue);
    });

    test("identifies React elements of specific types", () {
      expect(ReactTestUtils.isElementOfType(instance, customComponent), isTrue);
    });

    test("identifies composite component element", () {
      expect(ReactTestUtils.isCompositeComponentElement(instance), isTrue);
    });

    group("for rendered components", () {
      JsObject renderedInstance;

      setUp(() {
        renderedInstance = ReactTestUtils.renderIntoDocument(instance);
      });

      test("identifies React composite components", () {
        expect(ReactTestUtils.isCompositeComponent(renderedInstance), isTrue);
      });

      test("identifies React composite components of specific types", () {
        expect(ReactTestUtils.isCompositeComponentWithType(renderedInstance, customComponent), isTrue);
      });
    });
  });
}
