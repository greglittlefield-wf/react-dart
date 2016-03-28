import 'dart:html';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:react/react_dom.dart' as react_dom;
import 'package:react/react_test_utils.dart' as react_test_utils;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

void main() {
  useHtmlConfiguration();
  setClientConfiguration();

  ReactComponent render(ReactElement reactElement) {
    return react_test_utils.renderIntoDocument(reactElement);
  }

  react.Component getDartComponent(ReactComponent dartComponent) {
    return dartComponent.props.internal.component;
  }

  Map getDartComponentProps(ReactComponent dartComponent) {
    return getDartComponent(dartComponent).props;
  }

  Map getDartElementProps(ReactElement dartElement) {
    return dartElement.props.internal.props;
  }

  group('React component lifecycle:', () {
    group('default props', () {
      test('getDefaultProps() is only called once per component class and cached', () {
        expect(_DefaultPropsCachingTest.getDefaultPropsCallCount, 0);

        var DefaultPropsComponent = react.registerComponent(() => new _DefaultPropsCachingTest());
        var components = [
          render(DefaultPropsComponent({})),
          render(DefaultPropsComponent({})),
          render(DefaultPropsComponent({})),
        ];

        expect(components.map(getDartComponentProps), everyElement(containsPair('getDefaultPropsCallCount', 1)));
        expect(_DefaultPropsCachingTest.getDefaultPropsCallCount, 1);
      });

      group('are merged into props when the ReactElement is created when', () {
        test('the specified props are empty', () {
          var props = getDartElementProps(DefaultPropsTest({}));
          expect(props, containsPair('defaultProp', 'default'));
        });

        test('the default props are overridden', () {
          var props = getDartElementProps(DefaultPropsTest({'defaultProp': 'overridden'}));
          expect(props, containsPair('defaultProp', 'overridden'));
        });

        test('non-default props are added', () {
          var props = getDartElementProps(DefaultPropsTest({'otherProp': 'other'}));
          expect(props, containsPair('defaultProp', 'default'));
          expect(props, containsPair('otherProp', 'other'));
        });
      });

      group('are merged into props by the time the Dart Component is rendered when', () {
        test('the specified props are empty', () {
          var props = getDartComponentProps(render(DefaultPropsTest({})));
          expect(props, containsPair('defaultProp', 'default'));
        });

        test('the default props are overridden', () {
          var props = getDartComponentProps(render(DefaultPropsTest({'defaultProp': 'overridden'})));
          expect(props, containsPair('defaultProp', 'overridden'));
        });

        test('non-default props are added', () {
          var props = getDartComponentProps(render(DefaultPropsTest({'otherProp': 'other'})));
          expect(props, containsPair('defaultProp', 'default'));
          expect(props, containsPair('otherProp', 'other'));
        });
      });
    });
  });

  group('React component lifecycle:', () {
    Map matchCall(String memberName, {args: anything, props: anything, state: anything}) {
      return {
        'memberName': memberName,
        'arguments': args,
        'props': props,
        'state': state,
      };
    }

    test('recieves correct lifecycle calls on component mount', () {
      _LifecycleTest component = getDartComponent(
          render(LifecycleTest({}))
      );

      expect(component.lifecycleCalls, equals([
        matchCall('getInitialState'),
        matchCall('componentWillMount'),
        matchCall('render'),
        matchCall('componentDidMount'),
      ]));
    });

    test('recieves correct lifecycle calls on component unmount order', () {
      var mountNode = new DivElement();
      var instance = react_dom.render(LifecycleTest({}), mountNode);
      _LifecycleTest component = getDartComponent(instance);

      component.lifecycleCalls.clear();

      react_dom.unmountComponentAtNode(mountNode);

      expect(component.lifecycleCalls, equals([
        matchCall('componentWillUnmount'),
      ]));
    });

    test('recieves updated props with correct lifecycle calls', () {
      const Map initialProps = const {
        'initialProp': 'initial',
        'children': const []
      };
      const Map newProps = const {
        'newProp': 'new',
        'children': const []
      };

      const Map expectedState = const {};

      var mountNode = new DivElement();
      var instance = react_dom.render(LifecycleTest(initialProps), mountNode);
      _LifecycleTest component = getDartComponent(instance);

      component.lifecycleCalls.clear();

      react_dom.render(LifecycleTest(newProps), mountNode);

      expect(component.lifecycleCalls, equals([
        matchCall('componentWillReceiveProps', args: [newProps],                    props: initialProps),
        matchCall('shouldComponentUpdate',     args: [newProps, expectedState],     props: initialProps),
        matchCall('componentWillUpdate',       args: [newProps, expectedState],     props: initialProps),
        matchCall('render',                                                         props: newProps),
        matchCall('componentDidUpdate',        args: [initialProps, expectedState], props: newProps),
      ]));
    });

    test('updates state with correct lifecycle calls', () {
      const Map initialState = const {
        'initialState': 'initial',
      };
      const Map newState = const {
        'initialState': 'initial',
        'newState': 'new',
      };
      const Map stateDelta = const {
        'newState': 'new',
      };

      const Map expectedProps = const {'children': const []};

      _LifecycleTest component = getDartComponent(render(LifecycleTest({})));
      component.setState(initialState);

      component.lifecycleCalls.clear();

      component.setState(stateDelta);

      expect(component.lifecycleCalls, equals([
        matchCall('shouldComponentUpdate', args: [expectedProps, newState],     state: initialState),
        matchCall('componentWillUpdate',   args: [expectedProps, newState],     state: initialState),
        matchCall('render',                                                     state: newState),
        matchCall('componentDidUpdate',    args: [expectedProps, initialState], state: newState),
      ]));
    });
  });
}

class _DefaultPropsCachingTest extends react.Component {
  static int getDefaultPropsCallCount = 0;

  Map getDefaultProps() {
    getDefaultPropsCallCount++;
    return {
      'getDefaultPropsCallCount': getDefaultPropsCallCount
    };
  }

  render() => false;
}

ReactDartComponentFactoryProxy<_DefaultPropsTest> DefaultPropsTest = react.registerComponent(() => new _DefaultPropsTest());
class _DefaultPropsTest extends react.Component {
  static int getDefaultPropsCallCount = 0;

  Map getDefaultProps() => {
    'defaultProp': 'default'
  };

  render() => false;
}

ReactDartComponentFactoryProxy<_LifecycleTest> LifecycleTest = react.registerComponent(() => new _LifecycleTest());
class _LifecycleTest extends react.Component {
  List lifecycleCalls = [];

  void recordLifecycleCall(String memberName, [List arguments = const []]) {
    lifecycleCalls.add({
      'memberName': memberName,
      'arguments': arguments,
      'props': props == null ? null : new Map.from(props),
      'state': state == null ? null : new Map.from(state),
    });
  }

  void componentWillMount() => recordLifecycleCall('componentWillMount');
  void componentDidMount() => recordLifecycleCall('componentDidMount');
  void componentWillUnmount() => recordLifecycleCall('componentWillUnmount');

  void componentWillReceiveProps(newProps) {
    recordLifecycleCall('componentWillReceiveProps', [new Map.from(newProps)]);
  }
  void componentWillUpdate(nextProps, nextState) {
    recordLifecycleCall('componentWillUpdate', [new Map.from(nextProps), new Map.from(nextState)]);
  }
  void componentDidUpdate(prevProps, prevState) {
    recordLifecycleCall('componentDidUpdate', [new Map.from(prevProps), new Map.from(prevState)]);
  }

  bool shouldComponentUpdate(nextProps, nextState) {
    recordLifecycleCall('shouldComponentUpdate', [new Map.from(nextProps), new Map.from(nextState)]);
    return true;
  }

  dynamic render() {
    recordLifecycleCall('render');
    return react.div({});
  }

  Map getInitialState() {
    recordLifecycleCall('getInitialState');
    return {};
  }

  Map getDefaultProps() {
    recordLifecycleCall('getDefaultProps');
    return {};
  }
}
