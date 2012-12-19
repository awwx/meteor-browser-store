LocalStore
==========

Persistent local client storage for Meteor, reactively shared between browser tabs.

Meteor.LocalStore has the same API as Meteor's Session, but is persistent (stored locally in the browser using
[Web Storage](http://www.w3.org/TR/webstorage/),
also known as "Local Storage")
and is reactively shared across browser windows on the same device.

This means that if you are watching a LocalStore variable in one browser tab

    Template.mytemplate.foo = function () { return Meteor.LocalStore.get('foo'); };

and set it in another tab

    Meteor.LocalStore.set('foo', 'hello');

the change will be reactively visible in the first tab.

Items are stored in the browser's local storage with a key prefix of "Meteor.LocalStore.".  Setting an item to a `null` or `undefined` value removes the item from the store.  Items with the key prefix are loaded when the Meteor application starts up in the browser.

Local storage does not use the Internet or communicate with the Meteor server, and so changes are communicated reactively between tabs even if the browser is offline or the connection with the server is down.

Web applications opened with a URL with the same host and port will see the same local store, while applications run on different hosts or ports will have completely different stores (this is protection supplied by the browser's same orgin policy).  Thus pages opened on "http://app-one.meteor.com/" and "http://app-one.meteor.com/foo/bar" will see the same store, while a page opened on "http://app-two.meteor.com/" will see a different store.

Keep in mind during development that even if you switch to running a different Meteor application and refresh the browser page, old variables will still be in the store from the previous application as long as you use the same host and port such as "http://localhost:3000/".  Use `clear()` to erase all variables from the store for testing and development.


API
---

    Meteor.LocalStore.set(key, value)

Sets a variable in the local client store.  All tabs open on the application in the browser will be reactively updated with the new value.


    Meteor.Localstore.get(key)

Get the value of a variable in the local client store.  This is a reactive data source.


    Meteor.LocalStore.equals(key, value)

Like Session.equals, works like `Meteor.LocalStorage.get(key) === value`, but is a more efficient reactive data source.


    Meteor.LocalStore.clear()

Removes all variables from the local client store.
