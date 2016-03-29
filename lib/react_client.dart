// Copyright (c) 2013-2016, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library react_client;

import "dart:async";
import "dart:html";

import "package:js/js.dart";
import "package:react/react.dart";
import "package:react/react_client/js_interop_helpers.dart";
import 'package:react/react_client/react_interop.dart';
import "package:react/react_client/synthetic_event_interop.dart" as events;
import "package:react/react_dom.dart";
import "package:react/react_dom_server.dart";

export 'package:react/react_client/react_interop.dart' show ReactElement;

final EmptyObject emptyJsMap = new EmptyObject();

/// Type of [children] must be child or list of children, when child is [JsObject] or [String]
typedef ReactElement ReactComponentFactory(Map props, [dynamic children]);
typedef Component ComponentFactory();

/// The type of [Component.ref] specified as a callback.
///
/// See: <https://facebook.github.io/react/docs/more-about-refs.html#the-ref-callback-attribute>
typedef _CallbackRef(componentOrDomNode);

/// Creates ReactJS [Component] instances.
abstract class ReactComponentFactoryProxy implements Function {
  /// The type of [Component] created by this factory.
  get type;

  /// Returns a new rendered [Component] instance with the specified [props] and [children].
  ReactElement call(Map props, [dynamic children]);

  /// Used to implement a variadic version of [call], in which children may be specified as additional arguments.
  dynamic noSuchMethod(Invocation invocation);
}

dynamic jsifyChildren(dynamic children) {
  if (children is Iterable) {
    return children.toList(growable: false);
  } else {
    return children;
  }
}

/// Creates ReactJS [Component] instances for Dart components.
class ReactDartComponentFactoryProxy<TComponent extends Component> extends ReactComponentFactoryProxy {
  final ReactClass reactClass;
  final Function reactComponentFactory;
  final Map defaultProps;

  ReactDartComponentFactoryProxy(ReactClass reactClass, [this.defaultProps = const {}]) :
    this.reactClass = reactClass,
    this.reactComponentFactory = React.createFactory(reactClass);

  ReactClass get type => reactClass;

  ReactElement<TComponent> call(Map props, [dynamic children]) {
    // Convert Iterable children to Lists so that the JS can read them,
    // and so they don't get iterated twice when passed to the Dart component
    // and to the JS component.
    if (children is Iterable && children is! List) {
      children = children.toList();
    }

    return reactComponentFactory(
      generateExtendedJsProps(props, children, defaultProps: defaultProps),
      jsifyChildren(children)
    );
  }

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call && invocation.isMethod) {
      Map props = invocation.positionalArguments[0];
      List children = invocation.positionalArguments.sublist(1);

      markChildrenValidated(children);

      return reactComponentFactory(
        generateExtendedJsProps(props, children, defaultProps: defaultProps),
        jsifyChildren(children)
      );
    }

    return super.noSuchMethod(invocation);
  }

  /// Returns a [JsObject] version of the specified [props], preprocessed for consumption by ReactJS and prepared for
  /// consumption by the [react] library internals.
  static InteropProps generateExtendedJsProps(Map props, dynamic children, {Map defaultProps}) {
    if (children == null) {
      children = [];
    } else if (children is! Iterable) {
      children = [children];
    }

    // 1. Merge in defaults (if they were specified)
    // 2. Add specified props and children.
    // 3. Remove "reserved" props that should not be visible to the rendered component.

    // [1]
    Map extendedProps = defaultProps != null ? new Map.from(defaultProps) : {};
    extendedProps
      // [2]
      ..addAll(props)
      ..['children'] = children
      // [3]
      ..remove('key')
      ..remove('ref');

    var internal = new ReactDartComponentInternal()..props = extendedProps;

    var interopProps = new InteropProps(internal: internal);

    // Don't pass a key into InteropProps if one isn't defined, so that the value will
    // be `undefined` in the JS, which is ignored by React, whereas `null` isn't.
    if (props.containsKey('key')) {
      interopProps.key = props['key'];
    }

    if (props.containsKey('ref')) {
      var ref = props['ref'];

      // If the ref is a callback, pass React a function that will call it
      // with the Dart component instance, not the JsObject instance.
      if (ref is _CallbackRef) {
        interopProps.ref = allowInterop((ReactComponent instance) =>
            ref(instance == null ? null : instance.props.internal.component));
      } else {
        interopProps.ref = ref;
      }
    }

    return interopProps;
  }
}


/// Returns a new [ReactComponentFactory] which produces a new JS
/// [`ReactClass` component class](https://facebook.github.io/react/docs/top-level-api.html#react.createclass).
ReactComponentFactory _registerComponent(ComponentFactory componentFactory, [Iterable<String> skipMethods = const []]) {

  var zone = Zone.current;

  /// Wrapper for [Component.getDefaultProps].
  var getDefaultProps = allowInterop(() => zone.run(() {
    return new EmptyObject();
  }));


  final Map defaultProps = new Map.from(componentFactory().getDefaultProps());

  /// Wrapper for [Component.getInitialState].
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
      if (ref is Element) return ref;

      return (ref as ReactComponent).props?.internal?.component ?? ref;
    };

    var getDOMNode = () {
      return ReactDom.findDOMNode(jsThis);
    };

    Component component = componentFactory()
        ..initComponentInternal(internal.props, defaultProps, redraw, getRef, getDOMNode, jsThis);

    internal.component = component;
    internal.isMounted = false;
    internal.props = component.props;

    component.initStateInternal();
    return new EmptyObject();
  }));

  /// Wrapper for [Component.componentWillMount].
  var componentWillMount = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(() {
    var internal = jsThis.props.internal;
    internal.isMounted = true;
    internal.component
        ..componentWillMount()
        ..transferComponentState();
  }));

  /// Wrapper for [Component.componentDidMount].
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

  /// 1. Add [component] to [newArgs] to keep it in [InteropProps.internal]
  /// 2. Update [Component.props] using the value store to [Component.nextProps]
  ///    in [componentWillReceiveProps].
  /// 3. Update [Component.state] by calling [Component.transferComponentState]
  _afterPropsChange(Component component, InteropProps newArgs) {
    // [1]
    newArgs.internal.component = component;

    // [2]
    component.props = component.nextProps;

    // [3]
    component.transferComponentState();
  }

  /// Wrapper for [Component.componentWillReceiveProps].
  var componentWillReceiveProps =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps newArgs, [reactInternal]) => zone.run(() {
    var component = jsThis.props.internal.component;
    var nextProps = _getNextProps(component, newArgs);
    component.nextProps = nextProps;
    component.componentWillReceiveProps(nextProps);
  }));

  /// Wrapper for [Component.shouldComponentUpdate].
  var shouldComponentUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps newArgs, nextState, nextContext) => zone.run(() {
    Component component = jsThis.props.internal.component;
    /** use component.nextState where are stored nextState */
    if (component.shouldComponentUpdate(component.nextProps,
                                        component.nextState)) {
      return true;
    } else {
      // If component should not update, update props / transfer state because componentWillUpdate will not be called.
      _afterPropsChange(component, newArgs);
      return false;
    }
  }));

  /// Wrapper for [Component.componentWillUpdate].
  var componentWillUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, newArgs, nextState, [nextContext]) => zone.run(() {
    Component component = jsThis.props.internal.component;
    component.componentWillUpdate(component.nextProps,
                                  component.nextState);
    _afterPropsChange(component, newArgs);
  }));

  /// Wrapper for [Component.componentDidUpdate].
  ///
  /// Uses [prevState] which was transferred from [Component.nextState] in [componentWillUpdate].
  var componentDidUpdate =
      allowInteropCaptureThis((ReactComponent jsThis, InteropProps prevProps, prevState, prevContext) => zone.run(() {
    var prevInternalProps = prevProps.internal.props;
    Component component = jsThis.props.internal.component;
    component.componentDidUpdate(prevInternalProps, component.prevState);
  }));

  /// Wrapper for [Component.componentWillUnmount].
  var componentWillUnmount = allowInteropCaptureThis((ReactComponent jsThis, [reactInternal]) => zone.run(() {
    var internal = jsThis.props.internal;
    internal.isMounted = false;
    internal.component.componentWillUnmount();
  }));

  /// Wrapper for [Component.render].
  var render = allowInteropCaptureThis((ReactComponent jsThis) => zone.run(() {
    return jsThis.props.internal.component.render();
  }));

  /// Create the JS [`ReactClass` component class](https://facebook.github.io/react/docs/top-level-api.html#react.createclass)
  /// with wrapped functions.
  ReactClass reactComponentClass = React.createClass(new ReactClassConfig(
      displayName: componentFactory().displayName,
      componentWillMount: componentWillMount,
      componentDidMount: skipMethods.contains('componentDidMount') ? null : componentDidMount,
      componentWillReceiveProps: componentWillReceiveProps,
      shouldComponentUpdate: shouldComponentUpdate,
      componentWillUpdate: componentWillUpdate,
      componentDidUpdate: skipMethods.contains('componentDidUpdate') ? null : componentDidUpdate,
      componentWillUnmount: componentWillUnmount,
      getDefaultProps: getDefaultProps,
      getInitialState: getInitialState,
      render: render
  ));

  return new ReactDartComponentFactoryProxy(reactComponentClass, defaultProps);
}

/// Creates ReactJS [Component] instances for DOM components.
class ReactDomComponentFactoryProxy extends ReactComponentFactoryProxy {
  /// The name of the proxied DOM component.
  ///
  /// E.g. `'div'`, `'a'`, `'h1'`
  final String name;
  ReactDomComponentFactoryProxy(name) :
    this.name = name,
    this.factory = React.createFactory(name);

  @override
  String get type => name;

  final Function factory;

  @override
  ReactElement call(Map props, [dynamic children]) {
    convertProps(props);
    return factory(jsify(props), jsifyChildren(children));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call && invocation.isMethod) {
      Map props = invocation.positionalArguments[0];
      List children = invocation.positionalArguments.sublist(1);

      convertProps(props);
      markChildrenValidated(children);

      return factory(jsify(props), jsifyChildren(children));
    }

    return super.noSuchMethod(invocation);
  }

  /// Prepares props like event handlers for consumption by ReactJS DOM components.
  static void convertProps(Map props) {
    _convertEventHandlers(props);
  }
}

/// Create react-dart registered component for the HTML [Element].
_reactDom(String name) {
  return new ReactDomComponentFactoryProxy(name);
}

/// Convert event handler into wrapper and pass it only the Dart [Event] object converted from the [JsObject]
/// event.
_convertEventHandlers(Map args) {
  var zone = Zone.current;
  args.forEach((propKey, value) {
    var eventFactory = _eventPropKeyToEventFactory[propKey];
    if (eventFactory != null && value != null) {
      args[propKey] = allowInterop((event, [String domId, Event nativeEvent]) => zone.run(() {
        value(eventFactory(event));
      }));
    }
  });
}

/// A mapping from event prop keys to their respective event factories.
///
/// Used in [_convertEventHandlers] for efficient event handler conversion.
const Map<String, Function> _eventPropKeyToEventFactory = const <String, Function>{
  // SyntheticClipboardEvent
  'onCopy': syntheticClipboardEventFactory,
  'onCut': syntheticClipboardEventFactory,
  'onPaste': syntheticClipboardEventFactory,

  // SyntheticKeyboardEvent
  'onKeyDown': syntheticKeyboardEventFactory,
  'onKeyPress': syntheticKeyboardEventFactory,
  'onKeyUp': syntheticKeyboardEventFactory,

  // SyntheticFocusEvent
  'onFocus': syntheticFocusEventFactory,
  'onBlur': syntheticFocusEventFactory,

  // SyntheticFormEvent
  'onChange': syntheticFormEventFactory,
  'onInput': syntheticFormEventFactory,
  'onSubmit': syntheticFormEventFactory,
  'onReset': syntheticFormEventFactory,

  // SyntheticMouseEvent
  'onClick': syntheticMouseEventFactory,
  'onContextMenu': syntheticMouseEventFactory,
  'onDoubleClick': syntheticMouseEventFactory,
  'onDrag': syntheticMouseEventFactory,
  'onDragEnd': syntheticMouseEventFactory,
  'onDragEnter': syntheticMouseEventFactory,
  'onDragExit': syntheticMouseEventFactory,
  'onDragLeave': syntheticMouseEventFactory,
  'onDragOver': syntheticMouseEventFactory,
  'onDragStart': syntheticMouseEventFactory,
  'onDrop': syntheticMouseEventFactory,
  'onMouseDown': syntheticMouseEventFactory,
  'onMouseEnter': syntheticMouseEventFactory,
  'onMouseLeave': syntheticMouseEventFactory,
  'onMouseMove': syntheticMouseEventFactory,
  'onMouseOut': syntheticMouseEventFactory,
  'onMouseOver': syntheticMouseEventFactory,
  'onMouseUp': syntheticMouseEventFactory,

  // SyntheticTouchEvent
  'onTouchCancel': syntheticTouchEventFactory,
  'onTouchEnd': syntheticTouchEventFactory,
  'onTouchMove': syntheticTouchEventFactory,
  'onTouchStart': syntheticTouchEventFactory,

  // SyntheticUIEvent
  'onScroll': syntheticUIEventFactory,

  // SyntheticWheelEvent
  'onWheel': syntheticWheelEventFactory,
};

/// Wrapper for [SyntheticEvent].
SyntheticEvent syntheticEventFactory(events.SyntheticEvent e) {
  return new SyntheticEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type);
}

/// Wrapper for [SyntheticClipboardEvent].
SyntheticClipboardEvent syntheticClipboardEventFactory(events.SyntheticClipboardEvent e) {
  return new SyntheticClipboardEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type, e.clipboardData);
}

/// Wrapper for [SyntheticKeyboardEvent].
SyntheticKeyboardEvent syntheticKeyboardEventFactory(events.SyntheticKeyboardEvent e) {
  return new SyntheticKeyboardEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted,
      e.nativeEvent, e.target, e.timeStamp, e.type, e.altKey,
      e.char, e.charCode, e.ctrlKey, e.locale, e.location,
      e.key, e.keyCode, e.metaKey, e.repeat, e.shiftKey);
}

/// Wrapper for [SyntheticFocusEvent].
SyntheticFocusEvent syntheticFocusEventFactory(events.SyntheticFocusEvent e) {
  return new SyntheticFocusEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type, e.relatedTarget);
}

/// Wrapper for [SyntheticFormEvent].
SyntheticFormEvent syntheticFormEventFactory(events.SyntheticFormEvent e) {
  return new SyntheticFormEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type);
}

/// Wrapper for [SyntheticDataTransfer].
SyntheticDataTransfer syntheticDataTransferFactory(events.SyntheticDataTransfer dt) {
  if (dt == null) return null;
  List<File> files = [];
  if (dt.files != null) {
    for (int i = 0; i < dt.files.length; i++) {
      files.add(dt.files[i]);
    }
  }
  List<String> types = [];
  if (dt.types != null) {
    for (int i = 0; i < dt.types.length; i++) {
      types.add(dt.types[i]);
    }
  }
  var effectAllowed;
  try {
    // Works around a bug in IE where dragging from outside the browser fails.
    // Trying to access this property throws the error "Unexpected call to method or property access.".
    effectAllowed = dt.effectAllowed;
  } catch (exception) {
    effectAllowed = 'uninitialized';
  }
  return new SyntheticDataTransfer(dt.dropEffect, effectAllowed, files, types);
}

/// Wrapper for [SyntheticMouseEvent].
SyntheticMouseEvent syntheticMouseEventFactory(events.SyntheticMouseEvent e) {
  SyntheticDataTransfer dt = syntheticDataTransferFactory(e.dataTransfer);
  return new SyntheticMouseEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type, e.altKey, e.button, e.buttons, e.clientX, e.clientY,
      e.ctrlKey, dt, e.metaKey, e.pageX, e.pageY, e.relatedTarget, e.screenX,
      e.screenY, e.shiftKey);
}

/// Wrapper for [SyntheticTouchEvent].
SyntheticTouchEvent syntheticTouchEventFactory(events.SyntheticTouchEvent e) {
  return new SyntheticTouchEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type, e.altKey, e.changedTouches, e.ctrlKey, e.metaKey,
      e.shiftKey, e.targetTouches, e.touches);
}

/// Wrapper for [SyntheticUIEvent].
SyntheticUIEvent syntheticUIEventFactory(events.SyntheticUIEvent e) {
  return new SyntheticUIEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type, e.detail, e.view);
}

/// Wrapper for [SyntheticWheelEvent].
SyntheticWheelEvent syntheticWheelEventFactory(events.SyntheticWheelEvent e) {
  return new SyntheticWheelEvent(e.bubbles, e.cancelable, e.currentTarget,
      e.defaultPrevented, () => e.preventDefault(),
      () => e.stopPropagation(), e.eventPhase, e.isTrusted, e.nativeEvent,
      e.target, e.timeStamp, e.type, e.deltaX, e.deltaMode, e.deltaY, e.deltaZ);
}

dynamic _findDomNode(component) {
  return ReactDom.findDOMNode(component is Component ? component.jsThis : component);
}

void setClientConfiguration() {
  try {
    // Attempt to invoke JS interop methods, which will throw if the
    // corresponding JS functions are not available.
    React.isValidElement(null);
    ReactDom.findDOMNode(null);
  } on NoSuchMethodError catch (_) {
    throw new Exception('react.js and react_dom.js must be loaded.');
  }

  setReactConfiguration(_reactDom, _registerComponent, ReactDom.render,
      ReactDomServer.renderToString, ReactDomServer.renderToStaticMarkup,
      ReactDom.unmountComponentAtNode, _findDomNode);
  setReactDOMConfiguration(ReactDom.render, ReactDom.unmountComponentAtNode, _findDomNode);
  setReactDOMServerConfiguration(ReactDomServer.renderToString, ReactDomServer.renderToStaticMarkup);
}
