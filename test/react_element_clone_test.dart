import 'dart:js';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';
import 'package:react/react_test_utils.dart' as react_test_utils;

import 'dart:html';

class _Child extends react.Component {
  render() {
    return react.div(props, props['children']);
  }
}
ReactComponentFactory Child = react.registerComponent(() => new _Child());


class _Grandparent extends react.Component {
  render() {
    return react.div({}, Parent({}, [
      Child({
        'id': '1',
        'data-unmodified-prop': '1',
        'data-overridden-prop': '1'
      }, '1')
    ]));
  }
}
ReactComponentFactory Grandparent = react.registerComponent(() => new _Grandparent());

class _Parent extends react.Component {
  render() {
    return react.div({}, props['children'].map((child) {
      return cloneElement(child, {
        'id': '2',
        'data-overridden-prop': '2',
        'data-added-prop': '2'
      });
    }));
  }
}
ReactComponentFactory Parent = react.registerComponent(() => new _Parent());


void main() {
  useHtmlEnhancedConfiguration();
  setClientConfiguration();

  group('cloneElement', () {
    test('clones a Dart component as expected', () {
      JsObject component = react_test_utils.renderIntoDocument(Grandparent({}));

      Element grandparent = react_test_utils.getDomNode(component);
      Element parent = grandparent.children.first;
      Element child = parent.children.first;

      expect(grandparent, isNotNull);
      expect(parent, isNotNull);
      expect(child, isNotNull);

      expect(child.dataset, containsPair('unmodifiedProp', '1'));
      expect(child.dataset, containsPair('overriddenProp', '2'));
      expect(child.dataset, containsPair('addedProp', '2'));

      expect(child.text, equals('1'));
    });
  });
}
