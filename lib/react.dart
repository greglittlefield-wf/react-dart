// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A Dart library for building user interfaces.
 */
library react;

abstract class Component {
  Map props;

  dynamic ref;
  dynamic getDOMNode;
  dynamic _jsRedraw;

  /**
   * Bind the value of input to [state[key]].
   */
  bind(key) => [state[key], (value) => setState({key: value})];

  initComponentInternal(props, _jsRedraw, [ref = null, getDOMNode = null, defaultProps]) {
    this._jsRedraw = _jsRedraw;
    this.ref = ref;
    this.getDOMNode = getDOMNode;
    _initProps(props, defaultProps);
  }

  _initProps(props, defaultProps) {
    this.props = new Map.from(defaultProps)
      ..addAll(props);
  }

  initStateInternal() {
    this.state = new Map.from(getInitialState());
    /** Call transferComponent to get state also to _prevState */
    transferComponentState();
  }

  Map state = {};

  /**
   * private _nextState and _prevState are usefull for methods shouldComponentUpdate,
   * componentWillUpdate and componentDidUpdate.
   *
   * Use of theese private variables is implemented in react_client or react_server
   */
  Map _prevState = null;
  Map _nextState = null;
  /**
   * nextState and prevState are just getters for previous private variables _prevState
   * and _nextState
   *
   * if _nextState is null, then next state will be same as actual state,
   * so return state as nextState
   */
  Map get prevState => _prevState;
  Map get nextState => _nextState == null ? state : _nextState;

  /**
   * Transfers component _nextState to state and state to _prevState.
   * This is only way how to set _prevState.
   */
  void transferComponentState() {
    _prevState = state;
    if (_nextState != null) {
      state = _nextState;
    }
    _nextState = new Map.from(state);
  }

  void redraw() {
    setState({});
  }

  /**
   * set _nextState to state updated by newState
   * and call React original setState method with no parameter
   */
  void setState(Map newState) {
    if (newState != null) {
      _nextState.addAll(newState);
    }

    _jsRedraw();
  }

  /**
   * set _nextState to newState
   * and call React original setState method with no parameter
   */
  void replaceState(Map newState) {
    Map nextState = newState == null ? {} : new Map.from(newState);
    _nextState = nextState;
    _jsRedraw();
  }

  void componentWillMount() {}

  void componentDidMount(/*DOMElement */ rootNode) {}

  void componentWillReceiveProps(newProps) {}

  bool shouldComponentUpdate(nextProps, nextState) => true;

  void componentWillUpdate(nextProps, nextState) {}

  void componentDidUpdate(prevProps, prevState, /*DOMElement */ rootNode) {}

  void componentWillUnmount() {}

  Map getInitialState() => {};

  Map getDefaultProps() => {};

  dynamic render();

}

/** Synthetic event */

abstract class SyntheticEvent {
  bool get bubbles;
  bool get cancelable;
  get currentTarget;
  bool get defaultPrevented;
  num get eventPhase;
  bool get isTrusted;
  get nativeEvent;
  get target;
  num get timeStamp;
  String get type;

  void stopPropagation();
  void preventDefault();
}

abstract class SyntheticClipboardEvent extends SyntheticEvent {
  get clipboardData;
}

abstract class SyntheticKeyboardEvent extends SyntheticEvent {
  bool get altKey;
  String get char;
  bool get ctrlKey;
  String get locale;
  num get location;
  String get key;
  bool get metaKey;
  bool get repeat;
  bool get shiftKey;
  num get keyCode;
  num get charCode;
}

abstract class SyntheticFocusEvent extends SyntheticEvent {
  /*EventTarget*/ get relatedTarget;
}

abstract class SyntheticFormEvent extends SyntheticEvent {}

abstract class SyntheticDataTransfer {
  String get dropEffect;
  String get effectAllowed;
  List/*<File>*/ get files;
  List<String> get types;
}

abstract class SyntheticMouseEvent extends SyntheticEvent {
  bool get altKey;
  num get button;
  num get buttons;
  num get clientX;
  num get clientY;
  bool get ctrlKey;
  SyntheticDataTransfer get dataTransfer;
  bool get metaKey;
  num get pageX;
  num get pageY;
  /*DOMEventTarget*/get relatedTarget;
  num get screenX;
  num get screenY;
  bool get shiftKey;
}

abstract class SyntheticTouchEvent extends SyntheticEvent {
  bool get altKey;
  /*DOMTouchList*/ get changedTouches;
  bool get ctrlKey;
  bool get metaKey;
  bool get shiftKey;
  /*DOMTouchList*/ get targetTouches;
  /*DOMTouchList*/ get touches;
}

abstract class SyntheticUIEvent extends SyntheticEvent {
  num get detail;
  /*DOMAbstractView*/ get view;
}

abstract class SyntheticWheelEvent extends SyntheticEvent {
  num get deltaX;
  num get deltaMode;
  num get deltaY;
  num get deltaZ;
}

/**
 * client side rendering
 */
var render;

/**
 * server side rendering
 */
var renderToString;

/**
 * Similar to [renderToString], except this doesn't create extra DOM attributes such as
 * `data-react-id`, that React uses internally. This is useful if you want to use React
 * as a simple static page generator, as stripping away the extra attributes can save
 * lots of bytes.
 */
var renderToStaticMarkup;


/**
 * bool unmountComponentAtNode(HTMLElement);
 *
 * client side derendering - reverse operation to render
 *
 */
var unmountComponentAtNode;

/**
 * register component method to register component on both, client-side and server-side.
 */
var registerComponent;

/**
 * if this component has been mounted into the DOM, this returns the corresponding native browser DOM element.
 */
var findDOMNode;

/** Basic DOM elements
 * <var> is renamed to <variable> because var is reserved word in Dart.
 */
var a, abbr, address, area, article, aside, audio, b, base, bdi, bdo, big, blockquote, body, br,
button, canvas, caption, cite, code, col, colgroup, data, datalist, dd, del, details, dfn, dialog,
div, dl, dt, em, embed, fieldset, figcaption, figure, footer, form, h1, h2, h3, h4, h5, h6,
head, header, hr, html, i, iframe, img, input, ins, kbd, keygen, label, legend, li, link, main,
map, mark, menu, menuitem, meta, meter, nav, noscript, object, ol, optgroup, option, output,
p, param, picture, pre, progress, q, rp, rt, ruby, s, samp, script, section, select, small, source,
span, strong, style, sub, summary, sup, table, tbody, td, textarea, tfoot, th, thead, time,
title, tr, track, u, ul, variable, video, wbr;

/** SVG elements */
var circle, clipPath, defs, ellipse, g, line, linearGradient, mask, path, pattern, polygon, polyline,
radialGradient, rect, stop, svg, text, tspan;


/**
 * Create DOM components by creator passed
 */
_createDOMComponents(creator){
  a = creator('a');
  abbr = creator('abbr');
  address = creator('address');
  area = creator('area');
  article = creator('article');
  aside = creator('aside');
  audio = creator('audio');
  b = creator('b');
  base = creator('base');
  bdi = creator('bdi');
  bdo = creator('bdo');
  big = creator('big');
  blockquote = creator('blockquote');
  body = creator('body');
  br = creator('br');
  button = creator('button');
  canvas = creator('canvas');
  caption = creator('caption');
  cite = creator('cite');
  code = creator('code');
  col = creator('col');
  colgroup = creator('colgroup');
  data = creator('data');
  datalist = creator('datalist');
  dd = creator('dd');
  del = creator('del');
  details = creator('details');
  dfn = creator('dfn');
  dialog = creator('dialog');
  div = creator('div');
  dl = creator('dl');
  dt = creator('dt');
  em = creator('em');
  embed = creator('embed');
  fieldset = creator('fieldset');
  figcaption = creator('figcaption');
  figure = creator('figure');
  footer = creator('footer');
  form = creator('form');
  h1 = creator('h1');
  h2 = creator('h2');
  h3 = creator('h3');
  h4 = creator('h4');
  h5 = creator('h5');
  h6 = creator('h6');
  head = creator('head');
  header = creator('header');
  hr = creator('hr');
  html = creator('html');
  i = creator('i');
  iframe = creator('iframe');
  img = creator('img');
  input = creator('input');
  ins = creator('ins');
  kbd = creator('kbd');
  keygen = creator('keygen');
  label = creator('label');
  legend = creator('legend');
  li = creator('li');
  link = creator('link');
  main = creator('main');
  map = creator('map');
  mark = creator('mark');
  menu = creator('menu');
  menuitem = creator('menuitem');
  meta = creator('meta');
  meter = creator('meter');
  nav = creator('nav');
  noscript = creator('noscript');
  object = creator('object');
  ol = creator('ol');
  optgroup = creator('optgroup');
  option = creator('option');
  output = creator('output');
  p = creator('p');
  param = creator('param');
  picture = creator('picture');
  pre = creator('pre');
  progress = creator('progress');
  q = creator('q');
  rp = creator('rp');
  rt = creator('rt');
  ruby = creator('ruby');
  s = creator('s');
  samp = creator('samp');
  script = creator('script');
  section = creator('section');
  select = creator('select');
  small = creator('small');
  source = creator('source');
  span = creator('span');
  strong = creator('strong');
  style = creator('style');
  sub = creator('sub');
  summary = creator('summary');
  sup = creator('sup');
  table = creator('table');
  tbody = creator('tbody');
  td = creator('td');
  textarea = creator('textarea');
  tfoot = creator('tfoot');
  th = creator('th');
  thead = creator('thead');
  time = creator('time');
  title = creator('title');
  tr = creator('tr');
  track = creator('track');
  u = creator('u');
  ul = creator('ul');
  variable = creator('var');
  video = creator('video');
  wbr = creator('wbr');

  // SVG Elements
  circle = creator('circle');
  clipPath = creator('clipPath');
  defs = creator('defs');
  ellipse = creator('ellipse');
  g = creator('g');
  line = creator('line');
  linearGradient = creator('linearGradient');
  mask = creator('mask');
  path = creator('path');
  pattern = creator('pattern');
  polygon = creator('polygon');
  polyline = creator('polyline');
  radialGradient = creator('radialGradient');
  rect = creator('rect');
  stop = creator('stop');
  svg = creator('svg');
  text = creator('text');
  tspan = creator('tspan');
}

/**
 * set configuration based on passed functions.
 *
 * It pass arguments to global variables and run DOM components creation by dom Creator.
 */
setReactConfiguration(domCreator, customRegisterComponent, customRender, customRenderToString,
    customRenderToStaticMarkup, customUnmountComponentAtNode, customFindDOMNode){
  registerComponent = customRegisterComponent;
  render = customRender;
  renderToString = customRenderToString;
  renderToStaticMarkup = customRenderToStaticMarkup;
  unmountComponentAtNode = customUnmountComponentAtNode;
  findDOMNode = customFindDOMNode;
  // HTML Elements
  _createDOMComponents(domCreator);
}

