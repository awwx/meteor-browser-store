Package.describe({
  summary: "Persistent local browser storage, reactively shared across browser tabs"
});

Package.on_use(function (api) {
  api.use('localstorage-polyfill', 'client');
  api.add_files(['browser-store.js'], 'client');
});
