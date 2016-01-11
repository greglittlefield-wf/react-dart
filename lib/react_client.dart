// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library react_client;

import "package:react/react.dart";
import "package:js/js.dart";
import "dart:js";
import "dart:html";
import "dart:async";

/// Hacky (and hopefully temporary) way of getting the object proxied [JsObject].
///
/// Depends the following JS:
///     function unwrap(obj) {
///       return (obj && obj._jsObject) || obj;
///     }
///
/// ### Explanation
///
/// In Dartium, native JavaScript objects proxied by the `dart:js` and `package:js`
/// are properly unwrapped when passed to the JS side via `dart:js` method calls.
///
/// In dart2js code, however, the [JsObject] doesn't get unwrapped.
///
/// #### Example:
///
/// Dart:
///
///     JsObject jsProps = new JsObject.jsify({'value': 'test value'});
///     React.createElement('input', jsProps)
///
/// Expected value of props argument passed into `createElement`:
///     {value: 'test value'}
///
/// Value of props argument passed into `createElement` with dart2js:
///     {
///       _jsObject: {value: 'test value'}
///     }
@JS()
external dynamic unwrap(JsObject obj);

@JS()
class React {
  external static ReactClass createClass(ReactClassConfig reactClassConfig);
  external static Function createFactory(type);
  external static Element findDOMNode(object);

  external static Element cloneElement(element, [addedProps, newChildren]);

  external static ReactElement createElement(dynamic type, props, [dynamic children]);

  external static initializeTouchEvents(bool touchEnabled);
  external static ReactComponent render(ReactElement component, HtmlElement element);
  external static String renderToString(ReactElement component);
  external static String renderToStaticMarkup(ReactElement component);
  external static bool unmountComponentAtNode(HtmlElement element);

}

@JS()
@anonymous
class EmptyObject {
  external factory EmptyObject();
}

@JS()
@anonymous
class ReactElement {
  external String get key;

  external dynamic get ref;
  external InteropProps get props;
}

@JS()
@anonymous
class CloningProps {
  external String get key;
  external String get ref;

  external factory CloningProps({String key, dynamic ref});
}

@JS()
@anonymous
class ReactComponent<TComponent extends Component> {
  external InteropProps get props;
  external Map get refs;
  external setState(state);
}

@JS()
@anonymous
class ReactClassConfig {
  external factory ReactClassConfig({
    Function componentWillMount,
    Function componentDidMount,
    Function componentWillReceiveProps,
    Function shouldComponentUpdate,
    Function componentWillUpdate,
    Function componentDidUpdate,
    Function componentWillUnmount,
    Function getDefaultProps,
    Function getInitialState,
    Function render
  });
}

@JS()
@anonymous
class ReactClass {
  external set displayName(String value);
}

class Internal {
  Component component;
  bool isMounted;
  Map props;
}

@JS()
@anonymous
class InteropProps {
  external Internal get internal;
  external String get key;
  external dynamic get ref;

  external factory InteropProps({Internal internal, String key, dynamic ref});
}

final EmptyObject emptyJsMap = new EmptyObject();

const PROPS = 'props';
const INTERNAL = '__internal__';
const COMPONENT = 'component';
const IS_MOUNTED = 'isMounted';
const REFS = 'refs';

/**
 * Type of [children] must be child or list of childs, when child is JsObject or String
 */
typedef ReactElement ReactComponentFactory(Map props, [dynamic children]);
typedef Component ComponentFactory();

/**
 * A Dart function that creates React JS component instances.
 */
abstract class ReactComponentFactoryProxy implements Function {
  /**
   * The type of component created by this factory.
   */
  get type;

  /**
   * Returns a new rendered component instance with the specified props and children.
   */
  ReactElement call(Map props, [dynamic children]);

  /**
   * Used to implement a variadic version of [call], in which children may be specified as additional options.
   */
  dynamic noSuchMethod(Invocation invocation);
}

/**
 * A Dart function that creates React JS component instances for Dart components.
 */
class ReactDartComponentFactoryProxy<TReactElement extends ReactElement> extends ReactComponentFactoryProxy {
  final ReactClass reactClass;
  final Function reactComponentFactory;

  ReactDartComponentFactoryProxy(ReactClass reactClass) :
    this.reactClass = reactClass,
    this.reactComponentFactory = React.createFactory(reactClass);

  ReactClass get type => reactClass;

  TReactElement call(Map props, [dynamic children]) {
    // Convert Iterable children to JsArrays so that the JS can read them.
    // Use JsArrays instead of Lists, because automatic List conversion results in
    // react-id values being cluttered with ".$o:0:0:$_jsObject:" in dart2js-transpiled Dart.
    if (children is Iterable && children is! List) {
      children = children.toList();
    }

    return reactComponentFactory(
      generateExtendedJsProps(props, children),
      children
    );
  }

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call && invocation.isMethod) {
      Map props = invocation.positionalArguments[0];
      List children = invocation.positionalArguments.sublist(1);

      markChildrenValidated(children);

      return reactComponentFactory(
        generateExtendedJsProps(props, children),
        children
      );
    }

    return super.noSuchMethod(invocation);
  }

  /**
   * Returns a JsObject version of the specified props, preprocessed for consumption by React JS
   * and prepared for consumption by the react-dart wrapper internals.
   */
  static InteropProps generateExtendedJsProps(Map props, dynamic children) {
    if (children == null) {
      children = [];
    } else if (children is! Iterable) {
      children = [children];
    }

    Map extendedProps = new Map.from(props);
    extendedProps['children'] = children;

    var internal = new Internal()..props = extendedProps;

    var interopProps;
    // Don't pass a key into InteropProps if one isn't defined, so that the value will
    // be `undefined` in the JS, which is ignored by React, whereas `null` isn't.
    if (extendedProps.containsKey('key')) {
      interopProps = new InteropProps(internal: internal,
        key: extendedProps['key'],
        ref: extendedProps['ref']);
    } else {
      interopProps = new InteropProps(internal: internal,
        ref: extendedProps['ref']);
    }

    return interopProps;
  }
}

ReactComponentFactory _registerComponent(ComponentFactory componentFactory, [Iterable<String> skipMethods = const []]) {

  var zone = Zone.current;

  /**
   * wrapper for getDefaultProps.
   * Get internal, create component and place it to internal.
   *
   * Next get default props by component method and merge component.props into it
   * to update it with passed props from parent.
   *
   * @return jsProsp with internal with component.props and component
   */
  var getDefaultProps = allowInterop(() => zone.run(() {
    return new EmptyObject();
  }));

  /**
   * get initial state from component.getInitialState, put them to state.
   *
   * @return empty JsObject as default state for javascript react component
   */
  var getInitialState = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(() {

    var internal = jsThis.props.internal;
    var redraw = () {
      if (internal.isMounted) {
        jsThis.setState(emptyJsMap);
      }
    };

    var getRef = (name) {
      var ref = jsThis.refs[name];
      if (ref == null) return null;
      if (ref[PROPS][INTERNAL] != null) return ref[PROPS][INTERNAL][COMPONENT];
      else return ref;
    };

    var getDOMNode = () {
      return React.findDOMNode(jsThis);
    };

    Component component = componentFactory()
        ..initComponentInternal(internal.props, redraw, getRef, getDOMNode);

    internal.component = component;
    internal.isMounted = false;
    internal.props = component.props;

    component.initStateInternal();
    return new EmptyObject();
  }));

  /**
   * only wrap componentWillMount
   */
  var componentWillMount = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(() {
    jsThis.props.internal.isMounted = true;
    jsThis.props.internal.component
        ..componentWillMount()
        ..transferComponentState();
  }));

  /**
   * only wrap componentDidMount
   */
  var componentDidMount = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(() {
    //you need to get dom node by calling findDOMNode
    var rootNode = React.findDOMNode(jsThis);
    jsThis.props.internal.component.componentDidMount(rootNode);
  }));

  _getNextProps(Component component, InteropProps newArgs) {
    var newProps = newArgs.internal.props;
    return {}
      ..addAll(component.getDefaultProps())
      ..addAll(newProps ?? {});
  }

  _afterPropsChange(Component component, InteropProps newArgs) {
    /** add component to newArgs to keep component in internal */
    newArgs.internal.component = component;

    /** update component.props */
    component.props = _getNextProps(component, newArgs);

    /** update component.state */
    component.transferComponentState();
  }

  /**
   * Wrap componentWillReceiveProps
   */
  var componentWillReceiveProps =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps newArgs, [reactInternal]) => zone.run(() {
    var component = jsThis.props.internal.component;
    component.componentWillReceiveProps(_getNextProps(component, newArgs));
  }));

  /**
   * count nextProps from jsNextProps, get result from component,
   * and if shoudln't update, update props and transfer state.
   */
  var shouldComponentUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps newArgs, nextState, nextContext) => zone.run(() {
    Component component = jsThis.props.internal.component;
    /** use component.nextState where are stored nextState */
    if (component.shouldComponentUpdate(_getNextProps(component, newArgs),
                                        component.nextState)) {
      return true;
    } else {
      /**
       * if component shouldnt update, update props and tranfer state,
       * becasue willUpdate will not be called and so it will not do it.
       */
      _afterPropsChange(component, newArgs);
      return false;
    }
  }));

  /**
   * wrap component.componentWillUpdate and after that update props and transfer state
   */
  var componentWillUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, newArgs, nextState, [reactInternal]) => zone.run(() {
    Component component = jsThis.props.internal.component;
    component.componentWillUpdate(_getNextProps(component, newArgs),
                                  component.nextState);
    _afterPropsChange(component, newArgs);
  }));

  /**
   * wrap componentDidUpdate and use component.prevState which was trasnfered from state in componentWillUpdate.
   */
  var componentDidUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps prevProps, prevState, prevContext) => zone.run(() {
    var prevInternalProps = prevProps.internal.props;
    //you don't get root node as parameter but need to get it directly
    var rootNode = React.findDOMNode(jsThis);
    Component component = jsThis.props.internal.component;
    component.componentDidUpdate(prevInternalProps, component.prevState, rootNode);
  }));

  /**
   * only wrap componentWillUnmount
   */
  var componentWillUnmount = allowInteropCaptureThis((ReactComponent jsThis, [reactInternal]) => zone.run(() {
    var internal = jsThis.props.internal;
    internal.isMounted = false;
    internal.component.componentWillUnmount();
  }));

  /**
   * only wrap render
   */
  var render = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(() {
    return jsThis.props.internal.component.render();
  }));

  /**
   * create reactComponent with wrapped functions
   */
  ReactClass reactComponentClass = React.createClass(new ReactClassConfig(
      componentWillMount: componentWillMount,
      componentDidMount: componentDidMount,
      componentWillReceiveProps: componentWillReceiveProps,
      shouldComponentUpdate: shouldComponentUpdate,
      componentWillUpdate: componentWillUpdate,
      componentDidUpdate: componentDidUpdate,
      componentWillUnmount: componentWillUnmount,
      getDefaultProps: getDefaultProps,
      getInitialState: getInitialState,
      render: render
  ));

  /**
   * return ReactComponentFactory which produce react component with set props and children[s]
   */
  return new ReactDartComponentFactoryProxy(reactComponentClass);
}

/**
 * A Dart function that creates React JS component instances for DOM components.
 */
class ReactDomComponentFactoryProxy extends ReactComponentFactoryProxy {
  /**
   * The name of the proxied DOM component.
   * E.g., 'div', 'a', 'h1'
   */
  final String name;
  ReactDomComponentFactoryProxy(this.name);

  @override
  String get type => name;

  @override
  ReactElement call(Map props, [dynamic children]) {
    convertProps(props);
    var jsifiedProps = unwrap(new JsObject.jsify(props));

    // Convert Iterable children to JsArrays so that the JS can read them.
    // Use JsArrays instead of Lists, because automatic List conversion results in
    // react-id values being cluttered with ".$o:0:0:$_jsObject:" in dart2js-transpiled Dart.
    if (children is Iterable && children is! List) {
      children = children.toList();
    }

    return React.createElement(name, jsifiedProps, children);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call && invocation.isMethod) {
      Map props = invocation.positionalArguments[0];
      List children = invocation.positionalArguments.sublist(1);

      convertProps(props);
      var jsifiedProps = unwrap(new JsObject.jsify(props));

      markChildrenValidated(children);

      return React.createElement(name, jsifiedProps, children);
    }

    return super.noSuchMethod(invocation);
  }

  /**
   * Prepares the bound values, event handlers, and style props for consumption by React JS DOM components.
   */
  static void convertProps(Map props) {
    _convertBoundValues(props);
    _convertEventHandlers(props);
  }
}

/// Mark each child in children as validated so that React doesn't emit key warnings.
///
/// ___Only for use with variadic children.___
void markChildrenValidated(List<dynamic> children) {
  children.forEach((child) {
    if (child is JsObject) {
      var store = child['_store'];
      if (store != null) {
        store['validated'] = true;
    }
  }
  });
}

/**
 * create dart-react registered component for html tag.
 */
_reactDom(String name) {
  return new ReactDomComponentFactoryProxy(name);
}

/**
 * Recognize if type of input (or other element) is checkbox by it's props.
 */
_isCheckbox(props) {
  return props['type'] == 'checkbox';
}

/**
 * get value from DOM element.
 *
 * If element is checkbox, return bool, else return value of "value" attribute
 */
_getValueFromDom(domElem) {
  var props = domElem.attributes;
  if (_isCheckbox(props)) {
    return domElem.checked;
  } else {
    return domElem.value;
  }
}

/**
 * set value to props based on type of input.
 *
 * Specialy, it recognized chceckbox.
 */
_setValueToProps(Map props, val) {
  if (_isCheckbox(props)) {
    if(val) {
      props['checked'] = true;
    } else {
      if(props.containsKey('checked')) {
         props.remove('checked');
      }
    }
  } else {
    props['value'] = val;
  }
}

/**
 * convert bound values to pure value
 * and packed onchanged function
 */
_convertBoundValues(Map args) {
  var boundValue = args['value'];
  if (args['value'] is List) {
    _setValueToProps(args, boundValue[0]);
    args['value'] = boundValue[0];
    var onChange = args["onChange"];
    /**
     * put new function into onChange event hanlder.
     *
     * If there was something listening for taht event,
     * trigger it and return it's return value.
     */
    args['onChange'] = (e) {
      boundValue[1](_getValueFromDom(e.target));
      if(onChange != null)
        return onChange(e);
    };
  }
}


/**
 * Convert event pack event handler into wrapper
 * and pass it only dart object of event
 * converted from JsObject of event.
 */
_convertEventHandlers(Map args) {
  var zone = Zone.current;
  args.forEach((key, value) {
    if (value == null) {
      // If the handler is null, don't attempt to wrap/call it.
      return;
    }
    var eventFactory;
    if (_syntheticClipboardEvents.contains(key)) {
      eventFactory = syntheticClipboardEventFactory;
    } else if (_syntheticKeyboardEvents.contains(key)) {
      eventFactory = syntheticKeyboardEventFactory;
    } else if (_syntheticFocusEvents.contains(key)) {
      eventFactory = syntheticFocusEventFactory;
    } else if (_syntheticFormEvents.contains(key)) {
      eventFactory = syntheticFormEventFactory;
    } else if (_syntheticMouseEvents.contains(key)) {
      eventFactory = syntheticMouseEventFactory;
    } else if (_syntheticTouchEvents.contains(key)) {
      eventFactory = syntheticTouchEventFactory;
    } else if (_syntheticUIEvents.contains(key)) {
      eventFactory = syntheticUIEventFactory;
    } else if (_syntheticWheelEvents.contains(key)) {
      eventFactory = syntheticWheelEventFactory;
    } else return;
    args[key] = (JsObject e, [String domId]) => zone.run(() {
      value(eventFactory(e));
    });
  });
}

SyntheticEvent syntheticEventFactory(JsObject e) {
  return new SyntheticEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"]);
}

SyntheticEvent syntheticClipboardEventFactory(JsObject e) {
  return new SyntheticClipboardEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["clipboardData"]);
}

SyntheticEvent syntheticKeyboardEventFactory(JsObject e) {
  return new SyntheticKeyboardEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"],
      e["nativeEvent"], e["target"], e["timeStamp"], e["type"], e["altKey"],
      e["char"], e["charCode"], e["ctrlKey"], e["locale"], e["location"],
      e["key"], e["keyCode"], e["metaKey"], e["repeat"], e["shiftKey"]);
}

SyntheticEvent syntheticFocusEventFactory(JsObject e) {
  return new SyntheticFocusEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["relatedTarget"]);
}

SyntheticEvent syntheticFormEventFactory(JsObject e) {
  return new SyntheticFormEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"]);
}

SyntheticDataTransfer syntheticDataTransferFactory(JsObject dt) {
  if (dt == null) return null;
  List<File> files = [];
  if (dt["files"] != null) {
    for (int i = 0; i < dt["files"]["length"]; i++) {
      files.add(dt["files"][i]);
    }
  }
  List<String> types = [];
  if (dt["types"] != null) {
    for (int i = 0; i < dt["types"]["length"]; i++) {
      types.add(dt["types"][i]);
    }
  }
  var effectAllowed;
  try {
    // Works around a bug in IE where dragging from outside the browser fails.
    // Trying to access this property throws the error "Unexpected call to method or property access.".
    effectAllowed = dt["effectAllowed"];
  } catch (exception) {
    effectAllowed = "uninitialized";
  }
  return new SyntheticDataTransfer(dt["dropEffect"], effectAllowed, files, types);
}

SyntheticEvent syntheticMouseEventFactory(JsObject e) {
  SyntheticDataTransfer dt = syntheticDataTransferFactory(e["dataTransfer"]);
  return new SyntheticMouseEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["altKey"], e["button"], e["buttons"], e["clientX"], e["clientY"],
      e["ctrlKey"], dt, e["metaKey"], e["pageX"], e["pageY"], e["relatedTarget"], e["screenX"],
      e["screenY"], e["shiftKey"]);
}

SyntheticEvent syntheticTouchEventFactory(JsObject e) {
  return new SyntheticTouchEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["altKey"], e["changedTouches"], e["ctrlKey"], e["metaKey"],
      e["shiftKey"], e["targetTouches"], e["touches"]);
}

SyntheticEvent syntheticUIEventFactory(JsObject e) {
  return new SyntheticUIEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["detail"], e["view"]);
}

SyntheticEvent syntheticWheelEventFactory(JsObject e) {
  return new SyntheticWheelEvent(e["bubbles"], e["cancelable"], e["currentTarget"],
      e["defaultPrevented"], () => e.callMethod("preventDefault", []),
      () => e.callMethod("stopPropagation", []), e["eventPhase"], e["isTrusted"], e["nativeEvent"],
      e["target"], e["timeStamp"], e["type"], e["deltaX"], e["deltaMode"], e["deltaY"], e["deltaZ"]);
}

Set _syntheticClipboardEvents = new Set.from(["onCopy", "onCut", "onPaste",]);

Set _syntheticKeyboardEvents = new Set.from(["onKeyDown", "onKeyPress",
    "onKeyUp",]);

Set _syntheticFocusEvents = new Set.from(["onFocus", "onBlur",]);

Set _syntheticFormEvents = new Set.from(["onChange", "onInput", "onSubmit",
]);

Set _syntheticMouseEvents = new Set.from(["onClick", "onContextMenu",
    "onDoubleClick", "onDrag", "onDragEnd", "onDragEnter", "onDragExit",
    "onDragLeave", "onDragOver", "onDragStart", "onDrop", "onMouseDown",
    "onMouseEnter", "onMouseLeave", "onMouseMove", "onMouseOut",
    "onMouseOver", "onMouseUp",]);

Set _syntheticTouchEvents = new Set.from(["onTouchCancel", "onTouchEnd",
    "onTouchMove", "onTouchStart",]);

Set _syntheticUIEvents = new Set.from(["onScroll",]);

Set _syntheticWheelEvents = new Set.from(["onWheel",]);

dynamic _findDomNode(component) {
  // if it's a dart component class, the mounted dom is returned from getDOMNode
  // which has jsComponent closured inside and calls on it findDOMNode
  if (component is Component) return component.getDOMNode();
  //otherwise we have js component so pass it in findDOM node
  return React.findDOMNode(component);
}

void setClientConfiguration() {
  React.initializeTouchEvents(true);
  setReactConfiguration(_reactDom, _registerComponent, React.render, React.renderToString,
      React.renderToStaticMarkup, React.unmountComponentAtNode, _findDomNode);
}
