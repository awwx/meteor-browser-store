BrowserStore
============

Persistent local browser storage for Meteor, reactively shared across
browser tabs.


Description
-----------

Meteor.BrowserStore is designed to store small amounts of key/value
data in the browser.

The data is shared reactively across browser tabs and windows (in the
same browser), so if you are watching a BrowserStore variable in one
browser tab

    Template.mytemplate.foo = function () {
      return Meteor.BrowserStore.get('foo');
    };

and set it in another tab open to the same application

    Meteor.BrowserStore.set('foo', 'hello');

the change will be reactively visible in the first tab.

Browser storage does not use the Internet or communicate with the
Meteor server, and so changes are communicated reactively between tabs
even if the browser is offline or the connection with the server is
down.

Web applications opened with a URL with the same host and port will
see the same store, while applications run on different hosts or ports
will have completely separate stores (this is protection supplied by
the browser's same origin policy).  Thus pages opened on
"http://app-one.meteor.com/" and "http://app-one.meteor.com/foo/bar"
will see the same store, while a page opened on
"http://app-two.meteor.com/" will see a different store.

Keep in mind during development that even if you switch to running a
different Meteor application and refresh the browser page, old
variables will still be in the store from the previous application as
long as you use the same host and port such as
"http://localhost:3000/".


API
---

BrowserStore has a similar API to Meteor's Session:


    Meteor.BrowserStore.set(key, value)

Sets a variable in the browser store.  `value` can be any value that
can be serialized with `JSON.stringify` (which includes strings,
numbers, true, false, null, and arrays and objects of these values).

Setting a key to `null` or `undefined` will delete the key from store.
Getting a key which isn't present returns `null`, so after a set of
`undefined` a get will return `null`.

All tabs open on the application in the browser will be reactively
updated with the new value.


    Meteor.Browserstore.get(key)

Get the value of a variable in the browser store.  This is a reactive
data source.

If the key isn't present in the store `null` is returned.


    Meteor.BrowserStore.equals(key, value)

Like Session.equals, works like `Meteor.BrowserStorage.get(key) ===
value`, but is a more efficient reactive data source.


Implementation
--------------

For browsers where it is available, data is stored in [Web
Storage](http://www.w3.org/TR/webstorage/) (also known as "Local
Storage").  In IE 6 and 7, data is stored using IE's "userdata"
feature, implemented by the localstorage_polyfill package.

Changes are polled for in Chrome (due to
[Chrome bug #152424](http://code.google.com/p/chromium/issues/detail?id=152424))
and in IE 6 and 7 (because they don't have the storage event).

In other browsers polling isn't necessary because we are able to
listen for the storage event instead.

Items are stored in the browser's local storage with a key prefix of
"Meteor.BrowserStore.".  Setting an item to a `null` or `undefined`
value removes the item from the store.

For the non-polling implementation items with the key prefix are
loaded when the Meteor application starts up in the browser.

When polling, the item is read the first it is accessed with `get` or
`equals`, and then that key is added to the list of keys to poll for.
