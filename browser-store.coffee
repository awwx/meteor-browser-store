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

Meteor.BrowserStore = _.extend({}, {
    keys: {}, # key -> value
    keyDeps: {}, # key -> _ContextSet
    keyValueDeps: {}, # key -> value -> _ContextSet

    _save: (key, value) ->
      if value?
        localStorage.setItem(localStoragePrefix + key, value)
      else
        localStorage.removeItem(localStoragePrefix + key)

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

    get: `function (key) {
      var self = this;
      self._ensureKey(key);
      self.keyDeps[key].addCurrentContext();
      return parse(self.keys[key]);
    }`,

    equals: `function (key, value) {
      var self = this;
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

    _each: `function (callback) {
      var len = localStorage.length;
      var key, localStorageKey;
      for (var i = 0;  i < len;  ++i) {
        localStorageKey = localStorage.key(i)
        key = itemKey(localStorageKey)
        if (key) {
          callback(key, localStorage.getItem(localStorageKey));
        }
      }
    }`,

    clear: ->
      toRemove = []
      @_each (key) => toRemove.push(key)
      @set(key, null) for key in toRemove

  })


on_storage = (event) ->
  if key = itemKey(event.key)
    Meteor.BrowserStore._cacheSet(key, event.newValue)
  undefined

Meteor.startup ->

  Meteor.BrowserStore._each (key, val) ->
    Meteor.BrowserStore._cacheSet(key, val)

  if window.addEventListener
    window.addEventListener 'storage', on_storage, false
  else if window.attachEvent
    window.attachEvent 'onstorage', on_storage

  undefined
