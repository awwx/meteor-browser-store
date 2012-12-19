Package.describe({
  summary: "reactive local client storage, shared across browser windows"
});

Package.on_use(function (api) {
  api.add_files(['localstore.js'], 'client');
});
