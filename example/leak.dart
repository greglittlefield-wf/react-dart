import "dart:html";

import "package:react/react.dart" as react;
import "package:react/react_client.dart";
import "package:react/react_dom.dart" as react_dom;

void main() {
  setClientConfiguration();

  var b = B({});

  react_dom.render(
    A({}, [
      b
    ]),
    querySelector('#test_unmount'),
  );

  react_dom.render(
    A({'renderChildren': false}, [
      b
    ]),
    querySelector('#test_unmount'),
  );
}


var A = react.registerComponent(() => new _A());
class _A extends react.Component {
  getDefaultProps() => {'renderChildren': true};

  render() => react.div({'id': 'A'}, props['renderChildren'] ? props['children'] : null);
}

var B = react.registerComponent(() => new _B());
class _B extends react.Component {
  render() => react.div({'id': 'B'}, props['children']);
}
