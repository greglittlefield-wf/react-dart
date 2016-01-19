// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library react_client;

import "dart:async";
import "dart:html";

import "package:js/js.dart";
import "package:react/react.dart";
import "package:react/react_client/synthetic_event.dart" as events;

@JS('eval')
external dynamic _eval(String source);

@JS()
external dynamic _getProperty(jsObj, String key);

@JS()
external dynamic _setProperty(jsObj, String key, value);

typedef dynamic _GetPropertyFn(jsObj, String key);
typedef dynamic _SetPropertyFn(jsObj, String key, value);

final _GetPropertyFn getProperty = (() {
  _eval(r'''
    function _getProperty(obj, key) {
      return obj[key];
    }
  ''');

  return _getProperty;
})();

final _SetPropertyFn setProperty = (() {
  _eval(r'''
    function _setProperty(obj, key, value) {
      return obj[key] = value;
    }
  ''');

  return _setProperty;
})();


@JS()
class React {
  external static ReactClass createClass(ReactClassConfig reactClassConfig);
  external static Function createFactory(type);
  external static Element findDOMNode(object);

  external static ReactElement cloneElement(element, [addedProps, newChildren]);

  external static ReactElement createElement(dynamic type, props, [dynamic children]);

  external static initializeTouchEvents(bool touchEnabled);
  external static ReactComponent render(ReactElement component, HtmlElement element);
  external static String renderToString(ReactElement component);
  external static String renderToStaticMarkup(ReactElement component);
  external static bool unmountComponentAtNode(HtmlElement element);

  external static bool isValidElement(dynamic object);

}

@JS()
@anonymous
class EmptyObject {
  external factory EmptyObject();
}

@JS()
@anonymous
class ReactElementStore {
  external bool get validated;
  external set validated(bool value);
}

@JS()
@anonymous
class ReactElement {
  external ReactElementStore get _store;
  external dynamic get type;

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
  external get refs;
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

  external set key(String value);
  external set ref(dynamic value);

  external factory InteropProps({Internal internal, String key, dynamic ref});
}

final EmptyObject emptyJsMap = new EmptyObject();

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

dynamic jsifyChildren(dynamic children) {
  if (children is Iterable) {
    return children.toList(growable: false);
  } else {
    return children;
  }
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
    // Convert Iterable children to JsArrays so that the JS can read them,
    // and so they don't get iterated twice when passed to the Dart component
    // and to the JS component.
    if (children is Iterable && children is! List) {
      children = children.toList();
    }

    return reactComponentFactory(
      generateExtendedJsProps(props, children),
      jsifyChildren(children)
    );
  }

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call && invocation.isMethod) {
      Map props = invocation.positionalArguments[0];
      List children = invocation.positionalArguments.sublist(1);

      markChildrenValidated(children);

      return reactComponentFactory(
        generateExtendedJsProps(props, children),
        jsifyChildren(children)
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

    var interopProps = new InteropProps(internal: internal, ref: extendedProps['ref']);

    // Don't pass a key into InteropProps if one isn't defined, so that the value will
    // be `undefined` in the JS, which is ignored by React, whereas `null` isn't.
    if (extendedProps.containsKey('key')) {
      interopProps.key = extendedProps['key'];
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


  final Map defaultProps = new Map.from(componentFactory().getDefaultProps());

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
      var ref = getProperty(jsThis.refs, name);
      if (ref == null) return null;

      if (ref is ReactElement) {
        return ref.props?.internal?.component ?? ref;
      }

      return ref;
    };

    var getDOMNode = () {
      return React.findDOMNode(jsThis);
    };

    Component component = componentFactory()
        ..initComponentInternal(internal.props, redraw, getRef, getDOMNode, defaultProps);

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
    var internal = jsThis.props.internal;
    internal.isMounted = true;
    internal.component
        ..componentWillMount()
        ..transferComponentState();
  }));

  /**
   * only wrap componentDidMount
   */
  var componentDidMount = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(
      jsThis.props.internal.component.componentDidMount
  ));

  _getNextProps(Component component, InteropProps newArgs) {
    var nextProps = new Map.from(defaultProps);

    var newProps = newArgs.internal.props;
    if (newProps != null) {
      nextProps.addAll(newProps);
    }

    return nextProps;
  }

  _afterPropsChange(Component component, InteropProps newArgs) {
    /** add component to newArgs to keep component in internal */
    newArgs.internal.component = component;

    /** update component.props */
    component.props = component.nextProps;

    /** update component.state */
    component.transferComponentState();
  }

  /**
   * Wrap componentWillReceiveProps
   */
  var componentWillReceiveProps =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps newArgs, [reactInternal]) => zone.run(() {
    var component = jsThis.props.internal.component;
    var nextProps = _getNextProps(component, newArgs);
    component.nextProps = nextProps;
    component.componentWillReceiveProps(nextProps);
  }));

  /**
   * count nextProps from jsNextProps, get result from component,
   * and if shouldn't update, update props and transfer state.
   */
  var shouldComponentUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps newArgs, nextState, nextContext) => zone.run(() {
    Component component = jsThis.props.internal.component;
    /** use component.nextState where are stored nextState */
    if (component.shouldComponentUpdate(component.nextProps,
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
      allowInteropCaptureThis((ReactComponent jsThis, newArgs, nextState, [nextContext]) => zone.run(() {
    Component component = jsThis.props.internal.component;
    component.componentWillUpdate(component.nextProps,
                                  component.nextState);
    _afterPropsChange(component, newArgs);
  }));

  /**
   * wrap componentDidUpdate and use component.prevState which was trasnfered from state in componentWillUpdate.
   */
  var componentDidUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps prevProps, prevState, prevContext) => zone.run(() {
    var prevInternalProps = prevProps.internal.props;
    Component component = jsThis.props.internal.component;
    component.componentDidUpdate(prevInternalProps, component.prevState);
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
  ReactDomComponentFactoryProxy(name) :
    this.name = name,
    this.factory = React.createFactory(name);

  @override
  String get type => name;

  final Function factory;

  static jsifyProps(Map props) {
    var newObj = new EmptyObject();
    props.forEach((key, value) {
      setProperty(newObj, key, value is Map ? jsifyProps(value) : value);
    });
    return newObj;
  }

  @override
  ReactElement call(Map props, [dynamic children]) {
    convertProps(props);
    return factory(jsifyProps(props), jsifyChildren(children));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call && invocation.isMethod) {
      Map props = invocation.positionalArguments[0];
      List children = invocation.positionalArguments.sublist(1);

      convertProps(props);
      markChildrenValidated(children);

      return factory(jsifyProps(props), jsifyChildren(children));
    }

    return super.noSuchMethod(invocation);
  }

  /**
   * Prepares the bound values, event handlers, and style props for consumption by React JS DOM components.
   */
  static void convertProps(Map props) {
    _convertEventHandlers(props);
  }
}

/// Mark each child in children as validated so that React doesn't emit key warnings.
///
/// ___Only for use with variadic children.___
void markChildrenValidated(List<dynamic> children) {
  children.forEach((dynamic child) {
    // Use `isValidElement` since `is ReactElement` doesn't behave as expected.
    if (React.isValidElement(child)) {
      (child as ReactElement)._store?.validated = true;
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
 * Convert event pack event handler into wrapper
 * and pass it only dart object of event
 * converted from JsObject of event.
 */
_convertEventHandlers(Map args) {
  var zone = Zone.current;
  args.forEach((propKey, value) {
    var eventFactory = _eventPropKeyToEventFactory[propKey];
    if (eventFactory != null && value != null) {
      args[propKey] = allowInterop((event, [String domId]) => zone.run(() {
        value(eventFactory(event));
      }));
    }
  });
}

/// A mapping from event prop keys to their respective event factories.
///
/// Used in [_convertEventHandlers] for efficient event handler conversion.
final Map<String, Function> _eventPropKeyToEventFactory = (() {
  var map = <String, Function>{};

  _syntheticClipboardEvents.forEach((eventPropKey) => map[eventPropKey] = syntheticClipboardEventFactory);
  _syntheticKeyboardEvents.forEach((eventPropKey)  => map[eventPropKey] = syntheticKeyboardEventFactory);
  _syntheticFocusEvents.forEach((eventPropKey)     => map[eventPropKey] = syntheticFocusEventFactory);
  _syntheticFormEvents.forEach((eventPropKey)      => map[eventPropKey] = syntheticFormEventFactory);
  _syntheticMouseEvents.forEach((eventPropKey)     => map[eventPropKey] = syntheticMouseEventFactory);
  _syntheticTouchEvents.forEach((eventPropKey)     => map[eventPropKey] = syntheticTouchEventFactory);
  _syntheticUIEvents.forEach((eventPropKey)        => map[eventPropKey] = syntheticUIEventFactory);
  _syntheticWheelEvents.forEach((eventPropKey)     => map[eventPropKey] = syntheticWheelEventFactory);

  return map;
})();

events.SyntheticClipboardEvent syntheticClipboardEventFactory(e) => e as events.SyntheticClipboardEvent;
events.SyntheticKeyboardEvent  syntheticKeyboardEventFactory(e)  => e as events.SyntheticKeyboardEvent;
events.SyntheticFocusEvent     syntheticFocusEventFactory(e)     => e as events.SyntheticFocusEvent;
events.SyntheticFormEvent      syntheticFormEventFactory(e)      => e as events.SyntheticFormEvent;
events.SyntheticMouseEvent     syntheticMouseEventFactory(e)     => e as events.SyntheticMouseEvent;
events.SyntheticTouchEvent     syntheticTouchEventFactory(e)     => e as events.SyntheticTouchEvent;
events.SyntheticUIEvent        syntheticUIEventFactory(e)        => e as events.SyntheticUIEvent;
events.SyntheticWheelEvent     syntheticWheelEventFactory(e)     => e as events.SyntheticWheelEvent;

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
