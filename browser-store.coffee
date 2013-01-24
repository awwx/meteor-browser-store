# packages/localstorage-polyfill doesn't attempt to implement storage
# event.

polyfilled = not window.localStorage.length?


# Chrome bug http://code.google.com/p/chromium/issues/detail?id=152424
# means we can't rely on getting the current value the first time.

chrome = $.browser.chrome


# Can't rely on storage event.

polling = polyfilled or chrome


localStoragePrefix = 'Meteor.BrowserStore.'

itemKey = (localStorageKey) ->
  unless _.isString(localStorageKey)
    throw new Error('invalid key: ' + localStorageKey)
  if localStorageKey.substr(0, localStoragePrefix.length) is localStoragePrefix
    return localStorageKey.substr(localStoragePrefix.length)
  else
    return null

`
  var stringify = function (value) {
    if (value === undefined)
      return 'undefined';
    return JSON.stringify(value);
  };
  var parse = function (serialized) {
    if (serialized === undefined || serialized === 'undefined')
      return undefined;
    return JSON.parse(serialized);
  };
`

keysToPoll = []

Meteor.BrowserStore = _.extend({}, {
    keys: {}, # key -> value
    keyDeps: {}, # key -> _ContextSet
    keyValueDeps: {}, # key -> value -> _ContextSet

    _save: (key, value) ->
      if value?
        localStorage.setItem(localStoragePrefix + key, value)
      else
        localStorage.removeItem(localStoragePrefix + key)

    _fetch: (key) ->
      localStorage.getItem(localStoragePrefix + key)

    _cacheSet: `function (key, serializedValue) {
      var self = this;
      var oldSerializedValue = 'undefined';
      if (_.has(self.keys, key)) oldSerializedValue = self.keys[key];
      if (serializedValue === oldSerializedValue)
        return;
      self.keys[key] = serializedValue;

      var invalidateAll = function (cset) {
        cset && cset.invalidateAll();
      };

      invalidateAll(self.keyDeps[key]);
      if (self.keyValueDeps[key]) {
        invalidateAll(self.keyValueDeps[key][oldSerializedValue]);
        invalidateAll(self.keyValueDeps[key][serializedValue]);
      }
    }`,

    set: `function (key, value) {
      var self = this;
      value = stringify(value);
      self._cacheSet(key, value);
      self._save(key, value);
    }`,

    _initialFetch: (key) ->
      if polling and key not in keysToPoll
        keysToPoll.push(key)
        @_refresh key
      undefined

    get: (key) ->
      @_initialFetch(key)
      @_ensureKey(key)
      @keyDeps[key].addCurrentContext();
      return parse(@keys[key])

    equals: `function (key, value) {
      var self = this;
      self._initialFetch(key)
      var context = Meteor.deps.Context.current;

      // We don't allow objects (or arrays that might include objects) for
      // .equals, because JSON.stringify doesn't canonicalize object key
      // order. (We can make equals have the right return value by parsing the
      // current value and using _.isEqual, but we won't have a canonical
      // element of keyValueDeps[key] to store the context.) You can still use
      // "_.isEqual(Session.get(key), value)".
      //
      // XXX we could allow arrays as long as we recursively check that there
      // are no objects
      if (typeof value !== 'string' &&
          typeof value !== 'number' &&
          typeof value !== 'boolean' &&
          typeof value !== 'undefined' &&
          value !== null)
        throw new Error("BrowserStore.equals: value must be scalar");
      var serializedValue = stringify(value);

      if (context) {
        self._ensureKey(key);

        if (! _.has(self.keyValueDeps[key], serializedValue))
          self.keyValueDeps[key][serializedValue] = new Meteor.deps._ContextSet;

        var isNew = self.keyValueDeps[key][serializedValue].add(context);
        if (isNew) {
          context.onInvalidate(function () {
            // clean up [key][serializedValue] if it's now empty, so we don't
            // use O(n) memory for n = values seen ever
            if (self.keyValueDeps[key][serializedValue].isEmpty())
              delete self.keyValueDeps[key][serializedValue];
          });
        }
      }

      var oldValue = undefined;
      if (_.has(self.keys, key)) oldValue = parse(self.keys[key]);
      return oldValue === value;
    }`,

    _ensureKey: `function (key) {
      var self = this;
      if (!(key in self.keyDeps)) {
        self.keyDeps[key] = new Meteor.deps._ContextSet;
        self.keyValueDeps[key] = {};
      }
    }`,

    _each: (callback) ->
      if polyfilled
        throw new Error('_each is not supported in the polyfill implementation')
      len = localStorage.length
      for i in [0...len]
        localStorageKey = localStorage.key(i)
        key = itemKey(localStorageKey)
        if key
          callback(key, localStorage.getItem(localStorageKey))

    ## not supported in polyfill implementation
    # clear: ->
    #   toRemove = []
    #   @_each (key) => toRemove.push(key)
    #   @set(key, null) for key in toRemove

    _refresh: (key) ->
      @_cacheSet key, @_fetch(key)

    _poll: ->
      @_refresh key for key in keysToPoll
      undefined

    _onStorageEvent: (event) ->
      if key = itemKey(event.key)
        @_refresh key
      undefined

    _listenForStorageEvent: ->
      @_each (key, val) => @_cacheSet(key, val)

      if window.addEventListener
        window.addEventListener 'storage', _.bind(@_onStorageEvent, @), false
      else if window.attachEvent
        window.attachEvent 'onstorage', _.bind(@_onStorageEvent, @)

    _startup: ->
      if polling
        setInterval(_.bind(@_poll, @), 3000)
      else
        @_listenForStorageEvent()
  })


Meteor.startup -> Meteor.BrowserStore._startup()
