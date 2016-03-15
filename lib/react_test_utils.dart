// Copyright (c) 2016, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Notes
/// ---------------------------------------------------------------------------
///
/// 1.  This is of type `dynamic` out of necessity, since the actual type,
///     `ReactComponent | Element`, cannot be expressed in Dart's type system.
///
///     React 0.14 augments DOM nodes with its own properties and uses them as
///     DOM component instances. To Dart's JS interop, those instances look
///     like DOM nodes, so they get converted to the corresponding DOM node
///     interceptors, and thus cannot be used with a custom `@JS()` class.
///
///     So, React composite component instances will be of type
///     `ReactComponent`, whereas DOM component instance will be of type
///     `Element`.
///
library react.test_utils;

import 'dart:html';

import 'package:js/js.dart';
import 'package:react/react.dart';
import 'package:react/react_client.dart';

/// Returns the 'type' of a component.
///
/// For a DOM components, this with return the String corresponding to its tagName ('div', 'a', etc.).
/// For React.createClass()-based components, this with return the React class as a JsFunction.
dynamic getComponentType(ReactComponentFactory componentFactory) {
  if (componentFactory is ReactComponentFactoryProxy) {
    return componentFactory.type;
  }
  return null;
}

typedef bool ComponentTestFunction(/* [1] */ component);

@JS()
@anonymous
class EventData {
  external factory EventData();

  external bool get bubbles;
  external set bubbles(bool value);

  external bool get cancelable;
  external set cancelable(bool value);

  external EventTarget get currentTarget;
  external set currentTarget(EventTarget value);

  external bool get defaultPrevented;
  external set defaultPrevented(bool value);

  external int get eventPhase;
  external set eventPhase(int value);

  external bool get isTrusted;
  external set isTrusted(bool value);

  external Event get nativeEvent;
  external set nativeEvent(Event value);

  external EventTarget get target;
  external set target(EventTarget value);

  external int get timeStamp;
  external set timeStamp(int value);

  external String get type;
  external set type(String value);
}

/// Event simulation interface.
///
/// Provides methods for each type of event that can be handled by a React
/// component.  All methods are used in the same way:
///
///   Simulate.{eventName}(ReactComponent|Element componentOrNode, [Map] eventData)
///
/// This should include all events documented at:
/// http://facebook.github.io/react/docs/events.html
@JS('React.addons.TestUtils.Simulate')
class Simulate {
  external static void blur(/* [1] */ componentOrNode, [EventData eventData]);
  external static void change(/* [1] */ componentOrNode, [EventData eventData]);
  external static void click(/* [1] */ componentOrNode, [EventData eventData]);
  external static void contextMenu(/* [1] */ componentOrNode, [EventData eventData]);
  external static void copy(/* [1] */ componentOrNode, [EventData eventData]);
  external static void cut(/* [1] */ componentOrNode, [EventData eventData]);
  external static void doubleClick(/* [1] */ componentOrNode, [EventData eventData]);
  external static void drag(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragEnd(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragEnter(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragExit(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragLeave(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragOver(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragStart(/* [1] */ componentOrNode, [EventData eventData]);
  external static void drop(/* [1] */ componentOrNode, [EventData eventData]);
  external static void focus(/* [1] */ componentOrNode, [EventData eventData]);
  external static void input(/* [1] */ componentOrNode, [EventData eventData]);
  external static void keyDown(/* [1] */ componentOrNode, [EventData eventData]);
  external static void keyPress(/* [1] */ componentOrNode, [EventData eventData]);
  external static void keyUp(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseDown(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseMove(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseOut(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseOver(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseUp(/* [1] */ componentOrNode, [EventData eventData]);
  external static void paste(/* [1] */ componentOrNode, [EventData eventData]);
  external static void scroll(/* [1] */ componentOrNode, [EventData eventData]);
  external static void submit(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchCancel(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchEnd(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchMove(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchStart(/* [1] */ componentOrNode, [EventData eventData]);
  external static void wheel(/* [1] */ componentOrNode, [EventData eventData]);
}

/// Native event simulation interface.
///
/// Current implementation does not support change and keyPress native events
///
/// Provides methods for each type of event that can be handled by a React
/// component.  All methods are used in the same way:
///
///   SimulateNative.{eventName}(/* [1] */ componentOrNode, [Map] eventData)
@JS('React.addons.TestUtils.SimulateNative')
class SimulateNative {
  external static void blur(/* [1] */ componentOrNode, [EventData eventData]);
  external static void click(/* [1] */ componentOrNode, [EventData eventData]);
  external static void contextMenu(/* [1] */ componentOrNode, [EventData eventData]);
  external static void copy(/* [1] */ componentOrNode, [EventData eventData]);
  external static void cut(/* [1] */ componentOrNode, [EventData eventData]);
  external static void doubleClick(/* [1] */ componentOrNode, [EventData eventData]);
  external static void drag(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragEnd(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragEnter(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragExit(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragLeave(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragOver(/* [1] */ componentOrNode, [EventData eventData]);
  external static void dragStart(/* [1] */ componentOrNode, [EventData eventData]);
  external static void drop(/* [1] */ componentOrNode, [EventData eventData]);
  external static void focus(/* [1] */ componentOrNode, [EventData eventData]);
  external static void input(/* [1] */ componentOrNode, [EventData eventData]);
  external static void keyDown(/* [1] */ componentOrNode, [EventData eventData]);
  external static void keyUp(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseDown(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseMove(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseOut(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseOver(/* [1] */ componentOrNode, [EventData eventData]);
  external static void mouseUp(/* [1] */ componentOrNode, [EventData eventData]);
  external static void paste(/* [1] */ componentOrNode, [EventData eventData]);
  external static void scroll(/* [1] */ componentOrNode, [EventData eventData]);
  external static void submit(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchCancel(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchEnd(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchMove(/* [1] */ componentOrNode, [EventData eventData]);
  external static void touchStart(/* [1] */ componentOrNode, [EventData eventData]);
  external static void wheel(/* [1] */ componentOrNode, [EventData eventData]);
}

/// Traverse all components in tree and accumulate all components where
/// test(component) is true. This is not that useful on its own, but it's
/// used as a primitive for other test utils
///
/// Included in Dart for completeness
@JS('React.addons.TestUtils.findAllInRenderedTree')
external List<dynamic> findAllInRenderedTree(/* [1] */ tree, ComponentTestFunction test);

/// Like scryRenderedDOMComponentsWithClass() but expects there to be one
/// result, and returns that one result, or throws exception if there is
/// any other number of matches besides one.
@JS('React.addons.TestUtils.findRenderedDOMComponentWithClass')
external dynamic /* [1] */ findRenderedDOMComponentWithClass(/* [1] */ tree, String className);

/// Like scryRenderedDOMComponentsWithTag() but expects there to be one result,
/// and returns that one result, or throws exception if there is any other
/// number of matches besides one.
@JS('React.addons.TestUtils.findRenderedDOMComponentWithTag')
external dynamic /* [1] */ findRenderedDOMComponentWithTag(/* [1] */ tree, String tag);


@JS('React.addons.TestUtils.findRenderedComponentWithType')
external dynamic /* [1] */ _findRenderedComponentWithType(/* [1] */ tree, dynamic type);

/// Same as scryRenderedComponentsWithType() but expects there to be one result
/// and returns that one result, or throws exception if there is any other
/// number of matches besides one.
ReactComponent findRenderedComponentWithType(
    /* [1] */ tree, ReactComponentFactory componentType) {
  return _findRenderedComponentWithType(tree, getComponentType(componentType));
}

@JS('React.addons.TestUtils.isCompositeComponent')
external bool _isCompositeComponent(/* [1] */ instance);

/// Returns true if element is a composite component.
/// (created with React.createClass()).
bool isCompositeComponent(/* [1] */ instance) {
  return _isCompositeComponent(instance)
         // Workaround for DOM components being detected as composite: https://github.com/facebook/react/pull/3839
         && getProperty(instance, 'tagName') == null;
}

@JS('React.addons.TestUtils.isCompositeComponentWithType')
external bool _isCompositeComponentWithType(/* [1] */ instance, dynamic type);

/// Returns true if instance is a composite component.
/// (created with React.createClass()) whose type is of a React componentClass.
bool isCompositeComponentWithType(/* [1] */ instance, ReactComponentFactory componentClass) {
  return _isCompositeComponentWithType(instance, getComponentType(componentClass));
}

/// Returns true if instance is a DOM component (such as a <div> or <span>).
@JS('React.addons.TestUtils.isDOMComponent')
external bool isDOMComponent(/* [1] */ instance);

/// Returns true if [object] is a valid React component.
@JS('React.addons.TestUtils.isElement')
external bool isElement(dynamic object);

@JS('React.addons.TestUtils.isElementOfType')
external bool _isElementOfType(dynamic element, ReactComponentFactory componentClass);

/// Returns true if [element] is a ReactElement whose type is of a
/// React componentClass.
bool isElementOfType(dynamic element, ReactComponentFactory componentClass) {
  return _isElementOfType(element, getComponentType(componentClass));
}

@JS('React.addons.TestUtils.scryRenderedComponentsWithType')
external List<dynamic> /* [1] */ _scryRenderedComponentsWithType(/* [1] */ tree, dynamic type);

/// Finds all instances of components with type equal to componentClass.
List<dynamic> /* [1] */ scryRenderedComponentsWithType(/* [1] */ tree, ReactComponentFactory componentClass) {
  return _scryRenderedComponentsWithType(tree, getComponentType(componentClass));
}

@JS('React.addons.TestUtils.scryRenderedDOMComponentsWithClass')
/// Finds all instances of components in the rendered tree that are DOM
/// components with the class name matching className.
external List<dynamic> scryRenderedDOMComponentsWithClass(/* [1] */ tree, String className);

@JS('React.addons.TestUtils.scryRenderedDOMComponentsWithTag')
/// Finds all instances of components in the rendered tree that are DOM
/// components with the tag name matching tagName.
external List<dynamic> scryRenderedDOMComponentsWithTag(/* [1] */ tree, String tagName);

/// Render a Component into a detached DOM node in the document.
@JS('React.addons.TestUtils.renderIntoDocument')
external /* [1] */ renderIntoDocument(ReactElement instance);

// Use [findDOMNode] instead.
@deprecated
Element getDomNode(dynamic object) => findDOMNode(object);

/// Pass a mocked component module to this method to augment it with useful
/// methods that allow it to be used as a dummy React component. Instead of
/// rendering as usual, the component will become a simple <div> (or other tag
/// if mockTagName is provided) containing any provided children.
@JS('React.addons.TestUtils.mockComponent')
external ReactClass mockComponent(ReactClass componentClass, String mockTagName);

/// Returns a ReactShallowRenderer instance
///
/// More info on using shallow rendering: https://facebook.github.io/react/docs/test-utils.html#shallow-rendering
@JS('React.addons.TestUtils.createRenderer')
external ReactShallowRenderer createRenderer();

/// ReactShallowRenderer wrapper
///
/// Usage:
/// ```
/// ReactShallowRenderer shallowRenderer = createRenderer();
/// shallowRenderer.render(div({'className': 'active'}));
///
/// ReactElement renderedOutput = shallowRenderer.getRenderOutput();
/// Map props = getProps(renderedOutput);
/// expect(props['className'], 'active');
/// ```
///
/// See react_with_addons.js#ReactShallowRenderer
@JS()
class ReactShallowRenderer {
  /// Get the rendered output. [render] must be called first
  external ReactElement getRenderOutput();
  external void render(ReactElement element, [context]);
  external void unmount();
}
