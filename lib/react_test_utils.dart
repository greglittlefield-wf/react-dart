// Copyright (c) 2016, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library react.test_utils;

import 'dart:html';
import 'dart:js';

import 'package:js/js.dart';
import 'package:react/react.dart';
import 'package:react/react_client.dart';

/// Returns [component] if it is already a [JsObject], and converts [component] if
/// it is an [Element]. If [component] is neither a [JsObject] or an [Element], throws an
/// [ArgumentError].
///
/// React does not use the same type of object for primitive components as composite components,
/// and Dart converts the React objects used for primitive components to [Element]s automatically.
/// This is problematic in some cases - primarily the test utility methods that return [JsObject]s,
/// and render, which also needs to return a [JsObject]. This method can be used for handling this
/// by converting the [Element] back to a [JsObject].
JsObject normalizeReactComponent(dynamic component) {
  if (component is JsObject) return component;
  if (component is Element) return new JsObject.fromBrowserObject(component);
  if (component == null) return null;

  throw new ArgumentError('$component component is not a valid ReactComponent');
}

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

typedef bool ComponentTestFunction(ReactElement componentInstance);

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
///   Simulate.{eventName}(dynamic instanceOrNode, [Map] eventData)
///
/// This should include all events documented at:
/// http://facebook.github.io/react/docs/events.html
@JS('React.addons.TestUtils.Simulate')
class Simulate {
  external static void blur(dynamic instanceOrNode, [EventData eventData]);
  external static void change(dynamic instanceOrNode, [EventData eventData]);
  external static void click(dynamic instanceOrNode, [EventData eventData]);
  external static void contextMenu(dynamic instanceOrNode, [EventData eventData]);
  external static void copy(dynamic instanceOrNode, [EventData eventData]);
  external static void cut(dynamic instanceOrNode, [EventData eventData]);
  external static void doubleClick(dynamic instanceOrNode, [EventData eventData]);
  external static void drag(dynamic instanceOrNode, [EventData eventData]);
  external static void dragEnd(dynamic instanceOrNode, [EventData eventData]);
  external static void dragEnter(dynamic instanceOrNode, [EventData eventData]);
  external static void dragExit(dynamic instanceOrNode, [EventData eventData]);
  external static void dragLeave(dynamic instanceOrNode, [EventData eventData]);
  external static void dragOver(dynamic instanceOrNode, [EventData eventData]);
  external static void dragStart(dynamic instanceOrNode, [EventData eventData]);
  external static void drop(dynamic instanceOrNode, [EventData eventData]);
  external static void focus(dynamic instanceOrNode, [EventData eventData]);
  external static void input(dynamic instanceOrNode, [EventData eventData]);
  external static void keyDown(dynamic instanceOrNode, [EventData eventData]);
  external static void keyPress(dynamic instanceOrNode, [EventData eventData]);
  external static void keyUp(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseDown(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseMove(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseOut(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseOver(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseUp(dynamic instanceOrNode, [EventData eventData]);
  external static void paste(dynamic instanceOrNode, [EventData eventData]);
  external static void scroll(dynamic instanceOrNode, [EventData eventData]);
  external static void submit(dynamic instanceOrNode, [EventData eventData]);
  external static void touchCancel(dynamic instanceOrNode, [EventData eventData]);
  external static void touchEnd(dynamic instanceOrNode, [EventData eventData]);
  external static void touchMove(dynamic instanceOrNode, [EventData eventData]);
  external static void touchStart(dynamic instanceOrNode, [EventData eventData]);
  external static void wheel(dynamic instanceOrNode, [EventData eventData]);
}

/// Native event simulation interface.
///
/// Current implementation does not support change and keyPress native events
///
/// Provides methods for each type of event that can be handled by a React
/// component.  All methods are used in the same way:
///
///   SimulateNative.{eventName}(dynamic instanceOrNode, [Map] eventData)
@JS('React.addons.TestUtils.SimulateNative')
class SimulateNative {
  external static void blur(dynamic instanceOrNode, [EventData eventData]);
  external static void click(dynamic instanceOrNode, [EventData eventData]);
  external static void contextMenu(dynamic instanceOrNode, [EventData eventData]);
  external static void copy(dynamic instanceOrNode, [EventData eventData]);
  external static void cut(dynamic instanceOrNode, [EventData eventData]);
  external static void doubleClick(dynamic instanceOrNode, [EventData eventData]);
  external static void drag(dynamic instanceOrNode, [EventData eventData]);
  external static void dragEnd(dynamic instanceOrNode, [EventData eventData]);
  external static void dragEnter(dynamic instanceOrNode, [EventData eventData]);
  external static void dragExit(dynamic instanceOrNode, [EventData eventData]);
  external static void dragLeave(dynamic instanceOrNode, [EventData eventData]);
  external static void dragOver(dynamic instanceOrNode, [EventData eventData]);
  external static void dragStart(dynamic instanceOrNode, [EventData eventData]);
  external static void drop(dynamic instanceOrNode, [EventData eventData]);
  external static void focus(dynamic instanceOrNode, [EventData eventData]);
  external static void input(dynamic instanceOrNode, [EventData eventData]);
  external static void keyDown(dynamic instanceOrNode, [EventData eventData]);
  external static void keyUp(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseDown(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseMove(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseOut(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseOver(dynamic instanceOrNode, [EventData eventData]);
  external static void mouseUp(dynamic instanceOrNode, [EventData eventData]);
  external static void paste(dynamic instanceOrNode, [EventData eventData]);
  external static void scroll(dynamic instanceOrNode, [EventData eventData]);
  external static void submit(dynamic instanceOrNode, [EventData eventData]);
  external static void touchCancel(dynamic instanceOrNode, [EventData eventData]);
  external static void touchEnd(dynamic instanceOrNode, [EventData eventData]);
  external static void touchMove(dynamic instanceOrNode, [EventData eventData]);
  external static void touchStart(dynamic instanceOrNode, [EventData eventData]);
  external static void wheel(dynamic instanceOrNode, [EventData eventData]);
}

/// Traverse all components in tree and accumulate all components where
/// test(component) is true. This is not that useful on its own, but it's
/// used as a primitive for other test utils
///
/// Included in Dart for completeness
@JS('React.addons.TestUtils.findAllInRenderedTree')
external List<ReactComponent> findAllInRenderedTree(ReactComponent tree, ComponentTestFunction test);

/// Like scryRenderedDOMComponentsWithClass() but expects there to be one
/// result, and returns that one result, or throws exception if there is
/// any other number of matches besides one.
@JS('React.addons.TestUtils.findRenderedDOMComponentWithClass')
external ReactComponent findRenderedDOMComponentWithClass(ReactComponent tree, String className);

/// Like scryRenderedDOMComponentsWithTag() but expects there to be one result,
/// and returns that one result, or throws exception if there is any other
/// number of matches besides one.
@JS('React.addons.TestUtils.findRenderedDOMComponentWithTag')
external ReactComponent findRenderedDOMComponentWithTag(ReactComponent tree, String tag);


@JS('React.addons.TestUtils.findRenderedComponentWithType')
external ReactComponent _findRenderedComponentWithType(ReactComponent tree, dynamic type);

/// Same as scryRenderedComponentsWithType() but expects there to be one result
/// and returns that one result, or throws exception if there is any other
/// number of matches besides one.
ReactComponent findRenderedComponentWithType(
    ReactComponent tree, ReactComponentFactory componentType) {
  return _findRenderedComponentWithType(tree, getComponentType(componentType));
}

@JS('React.addons.TestUtils.isCompositeComponent')
external bool _isCompositeComponent(ReactComponent instance);

/// Returns true if element is a composite component.
/// (created with React.createClass()).
bool isCompositeComponent(ReactComponent instance) {
  return _isCompositeComponent(instance)
         // Workaround for DOM components being detected as composite: https://github.com/facebook/react/pull/3839
         && getProperty(instance, 'tagName') == null;
}

@JS('React.addons.TestUtils.isCompositeComponentWithType')
external bool _isCompositeComponentWithType(ReactComponent instance, dynamic type);

/// Returns true if instance is a composite component.
/// (created with React.createClass()) whose type is of a React componentClass.
bool isCompositeComponentWithType(ReactComponent instance, ReactComponentFactory componentClass) {
  return _isCompositeComponentWithType(instance, getComponentType(componentClass));
}

/// Returns true if instance is a DOM component (such as a <div> or <span>).
@JS('React.addons.TestUtils.isDOMComponent')
external bool isDOMComponent(ReactComponent instance);

/// Returns true if [object] is a valid React component.
@JS('React.addons.TestUtils.isElement')
external bool isElement(ReactComponent object);

@JS('React.addons.TestUtils.isElementOfType')
external bool _isElementOfType(ReactComponent element, ReactComponentFactory componentClass);

/// Returns true if element is a ReactElement whose type is of a
/// React componentClass.
bool isElementOfType(ReactComponent element, ReactComponentFactory componentClass) {
  return _isElementOfType(element, getComponentType(componentClass));
}

@JS('React.addons.TestUtils.scryRenderedComponentsWithType')
external List<ReactComponent> _scryRenderedComponentsWithType(ReactComponent tree, dynamic type);

/// Finds all instances of components with type equal to componentClass.
List<ReactComponent> scryRenderedComponentsWithType(ReactComponent tree, ReactComponentFactory componentClass) {
  return _scryRenderedComponentsWithType(tree, getComponentType(componentClass));
}

@JS('React.addons.TestUtils.scryRenderedDOMComponentsWithClass')
/// Finds all instances of components in the rendered tree that are DOM
/// components with the class name matching className.
external List<ReactComponent> scryRenderedDOMComponentsWithClass(ReactComponent tree, String className);

@JS('React.addons.TestUtils.scryRenderedDOMComponentsWithTag')
/// Finds all instances of components in the rendered tree that are DOM
/// components with the tag name matching tagName.
external List<ReactComponent> scryRenderedDOMComponentsWithTag(ReactComponent tree, String tagName);

/// Render a Component into a detached DOM node in the document.
@JS('React.addons.TestUtils.renderIntoDocument')
external ReactComponent renderIntoDocument(ReactElement instance);

// Use [findDOMNode] instead.
@deprecated
Element getDomNode(ReactComponent object) => findDOMNode(object);

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
/// JsObject renderedOutput = shallowRenderer.getRenderOutput();
/// expect(renderedOutput['props']['className'], 'active');
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
