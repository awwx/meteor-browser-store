Package.describe({
  summary: "Persistent local browser storage, reactively shared across browser tabs"
});

Package.on_use(function (api) {
  api.add_files(['browser-store.js'], 'client');
});
