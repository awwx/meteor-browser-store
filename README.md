BrowserStore
============

Persistent local browser storage for Meteor, reactively shared across
browser tabs.


Problems
--------

When an item is set in one browser window, the new value is broadcast
to any other browser windows that may be open (using the browser's
"storage" event).  Currently when a window receives the message, it
uses the value *in the message* as the new value of the item.  This is
buggy because the window (or another window) might have changed the
item's value itself between the time the first window set its value
and the second window received the message.

A solution would be to re-lookup the current value of the item on
receipt of the storage event (the message would be used only as a
trigger that the value may have changed).  However due to
[Chrome bug #152424](http://code.google.com/p/chromium/issues/detail?id=152424),
the second window may not see the new value when it reads from local storage.

So for Chrome at least, the only reliable solution may be to use a
store with transactions (Web SQL Database or IndexedDB)...


Description
-----------

Meteor.BrowserStore has the same API as Meteor's Session, but is
persistent (stored locally in the browser using
[Web Storage](http://www.w3.org/TR/webstorage/), also known as "Local
Storage") and is reactively shared across browser windows in the same
browser.

This means that if you are watching a BrowserStore variable in one
browser tab

    Template.mytemplate.foo = function () {
      return Meteor.BrowserStore.get('foo');
    };

and set it in another tab open to the same application

    Meteor.BrowserStore.set('foo', 'hello');

the change will be reactively visible in the first tab.

Items are stored in the browser's local storage with a key prefix of
"Meteor.BrowserStore.".  Setting an item to a `null` or `undefined`
value removes the item from the store.  Items with the key prefix are
loaded when the Meteor application starts up in the browser.

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
"http://localhost:3000/".  Use `clear()` to erase all variables from
the store for testing and development.


API
---

    Meteor.BrowserStore.set(key, value)

Sets a variable in the browser store.  All tabs open on the
application in the browser will be reactively updated with the new
value.


    Meteor.Browserstore.get(key)

Get the value of a variable in the browser store.  This is a reactive
data source.


    Meteor.BrowserStore.equals(key, value)

Like Session.equals, works like `Meteor.BrowserStorage.get(key) ===
value`, but is a more efficient reactive data source.


    Meteor.BrowserStore.clear()

Removes all variables from the browser store.
