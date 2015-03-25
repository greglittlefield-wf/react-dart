// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library react_test_utils;

import "package:react/react_client.dart" show ReactComponentFactory, ReactComponentFactoryProxy;
import "dart:js";
import "dart:html" show Element;

_getNestedJsObject(JsObject base, List<String> keys, [String errorIfNotFound='']) {
  JsObject object = base;
  for (String key in keys) {
    if (!object.hasProperty(key)) {
      throw 'Unable to resolve $key in $base${keys.join('.')}}.\n$errorIfNotFound';
    }
    object = object[key];
  }
  return object;
}

JsObject _ReactTestUtils = _getNestedJsObject(context, ['React', 'addons', 'TestUtils'],
  'React.addons.TestUtils not found. Ensure you\'ve included the React addons in your HTML file.'
  '\n  This:\n<script src="packages/react/react-with-addons.js"></script>'
  '\n  Not this:\n<script src="packages/react/react.js"></script>');

JsFunction getFactory(ReactComponentFactory reactComponentFactory) {
  if (reactComponentFactory is ReactComponentFactoryProxy) {
    return (reactComponentFactory as ReactComponentFactoryProxy).reactComponentFactory;
  }
  return null;
}

typedef bool ComponentTestFunction(JsObject componentInstance);

class ReactTestUtils {
  static JsObject renderIntoDocument(JsObject instance) =>
    _ReactTestUtils.callMethod('renderIntoDocument', [instance]);

  static bool isElement(JsObject element) =>
    _ReactTestUtils.callMethod('isElement', [element]);

  static bool isElementOfType(JsObject inst, ReactComponentFactory convenienceConstructor) =>
    _ReactTestUtils.callMethod('isElementOfType', [inst, getFactory(convenienceConstructor)]);

  static bool isDOMComponent(JsObject inst) =>
    _ReactTestUtils.callMethod('isDOMComponent', [inst]);

  static bool isDOMComponentElement(JsObject inst) =>
    _ReactTestUtils.callMethod('isDOMComponentElement', [inst]);

  static bool isCompositeComponent(JsObject inst) =>
    _ReactTestUtils.callMethod('isCompositeComponent', [inst]);

  static bool isCompositeComponentWithType(JsObject inst, ReactComponentFactory type) =>
    _ReactTestUtils.callMethod('isCompositeComponentWithType', [inst, getFactory(type)]);

  static bool isCompositeComponentElement(JsObject inst) =>
    _ReactTestUtils.callMethod('isCompositeComponentElement', [inst]);

  static bool isCompositeComponentElementWithType(JsObject inst, ReactComponentFactory type) =>
    _ReactTestUtils.callMethod('isCompositeComponentElementWithType', [inst, getFactory(type)]);

  static bool isTextComponent(JsObject inst) =>
    _ReactTestUtils.callMethod('isTextComponent', [inst]);

  static void findAllInRenderedTree(JsObject inst, ComponentTestFunction test) =>
    _ReactTestUtils.callMethod('findAllInRenderedTree', [inst, test]);

  /**
   * Finds all instance of components in the rendered tree that are DOM
   * components with the class name matching `className`.
   * @return an array of all the matches.
   */
  static JsObject scryRenderedDOMComponentsWithClass(JsObject root, String className) =>
    _ReactTestUtils.callMethod('scryRenderedDOMComponentsWithClass', [root, className]);

  /**
   * Like scryRenderedDOMComponentsWithClass but expects there to be one result,
   * and returns that one result, or throws exception if there is any other
   * number of matches besides one.
   * @return {!ReactDOMComponent} The one match.
   */
  static JsObject findRenderedDOMComponentWithClass(JsObject root, String className) =>
    _ReactTestUtils.callMethod('findRenderedDOMComponentWithClass', [root, className]);


  /**
   * Finds all instance of components in the rendered tree that are DOM
   * components with the tag name matching `tagName`.
   * @return an array of all the matches.
   */
  static JsObject scryRenderedDOMComponentsWithTag(JsObject root, String tagName) =>
    _ReactTestUtils.callMethod('scryRenderedDOMComponentsWithTag', [root, tagName]);

  /**
   * Like scryRenderedDOMComponentsWithTag but expects there to be one result,
   * and returns that one result, or throws exception if there is any other
   * number of matches besides one.
   * @return {!ReactDOMComponent} The one match.
   */
  static JsObject findRenderedDOMComponentWithTag(JsObject root, String tagName) =>
    _ReactTestUtils.callMethod('findRenderedDOMComponentWithTag', [root, tagName]);


  /**
   * Finds all instances of components with type equal to `componentType`.
   * @return an array of all the matches.
   */
  static JsObject scryRenderedComponentsWithType(JsObject root, String componentType) =>
    _ReactTestUtils.callMethod('scryRenderedComponentsWithType', [root, componentType]);

  /**
   * Same as `scryRenderedComponentsWithType` but expects there to be one result
   * and returns that one result, or throws exception if there is any other
   * number of matches besides one.
   * @return {!ReactComponent} The one match.
   */
  static JsObject findRenderedComponentWithType(JsObject root, String componentType) =>
    _ReactTestUtils.callMethod('findRenderedComponentWithType', [root, componentType]);

  /**
   * Pass a mocked component module to this method to augment it with
   * useful methods that allow it to be used as a dummy React component.
   * Instead of rendering as usual, the component will become a simple
   * <div> containing any provided children.
   *
   * @param {object} module the mock function object exported from a
   *                        module that defines the component to be mocked
   * @param {?string} mockTagName optional dummy root tag name to return
   *                              from render method (overrides
   *                              module.mockTagName if provided)
   * @return {object} the ReactTestUtils object (for chaining)
   */
  static JsObject mockComponent(Map module, String mockTagName) =>
    _ReactTestUtils.callMethod('mockComponent', [new JsObject.jsify(module), mockTagName]);

  /**
   * Simulates a top level event being dispatched from a raw event that occured
   * on an `Element` node.
   * @param topLevelType {Object} A type from `EventConstants.topLevelTypes`
   * @param {!Element} node The dom to simulate an event occurring on.
   * @param {?Event} fakeNativeEvent Fake native event to use in SyntheticEvent.
   */
  static JsObject simulateNativeEventOnNode(String topLevelType, Element node, fakeNativeEvent) =>
    _ReactTestUtils.callMethod('simulateNativeEventOnNode', [topLevelType, node, fakeNativeEvent]);

  /**
   * Simulates a top level event being dispatched from a raw event that occured
   * on the `ReactDOMComponent` `comp`.
   * @param topLevelType {Object} A type from `EventConstants.topLevelTypes`.
   * @param comp {!ReactDOMComponent}
   * @param {?Event} fakeNativeEvent Fake native event to use in SyntheticEvent.
   */
  static JsObject simulateNativeEventOnDOMComponent(String topLevelType, JsObject comp, fakeNativeEvent) =>
    _ReactTestUtils.callMethod('simulateNativeEventOnDOMComponent', [topLevelType,comp,fakeNativeEvent]);


  // TODO - 'Simulators'
}
