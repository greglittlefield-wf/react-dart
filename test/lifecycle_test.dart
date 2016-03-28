import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:react/react_test_utils.dart' as react_test_utils;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

void main() {
  useHtmlConfiguration();
  setClientConfiguration();

  ReactComponent render(ReactElement reactElement) {
    return react_test_utils.renderIntoDocument(reactElement);
  }

  Map getDartComponentProps(ReactComponent dartComponent) {
    return dartComponent.props.internal.component.props;
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
