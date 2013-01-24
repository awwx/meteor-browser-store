return unless Meteor.isClient

Template.renderPage.showHome   = -> Session.equals('route', '/')
Template.renderPage.showChild1 = -> Session.equals('route', '/test1/child1')
Template.renderPage.showChild2 = -> Session.equals('route', '/test1/child2')

Meteor.startup ->
  Session.set('route', window.location.pathname)
  switch window.location.pathname
    when '/'
      window.name = 'parent'
      parent_startup()
    when '/test1/child1'
      window.name = 'child1'
      child1_startup()
    when '/test1/child2'
      window.name = 'child2'
      child2_startup()


_when = window.when

pollFor = (fn) ->
  deferred = _when.defer()
  timer = null
  check = ->
    if fn()
      clearInterval(timer) if timer?
      timer = null
      deferred.resolve()
  timer = setInterval(check, 300)
  check()
  deferred.promise

ok_to_start_children = _when.defer()
home_template_rendered = _when.defer()

Session.set('ready', false)
Session.set('done', false)

Template.test1_home.ready = -> Session.get('ready')
Template.test1_home.done  = -> Session.get('done')

rendered = false
Template.test1_home.rendered = ->
  return if rendered
  rendered = true
  home_template_rendered.resolve()

_when.join(home_template_rendered, ok_to_start_children)
.then ->
  $('#iframes').append('''
    <iframe id="child1" src="/test1/child1"></iframe>
    <iframe id="child2" src="/test1/child2"></iframe>
  ''')

parent_startup = ->
  pollFor(-> $('#child2-got-it')[0]).then(-> Session.set('done', true))

  child1_awake = pollFor(-> $('#child1-awake')[0])
  child2_awake = pollFor(-> $('#child2-awake')[0])
  _when.join(child1_awake, child2_awake)
  .then(->
    $('body', $('#child1')[0].contentWindow.document).append('<div id="begin">begin</div>')
  )

  Meteor.BrowserStore.set('foo', null)
  ok_to_start_children.resolve()

message_parent = (msg) ->
  $('body', window.parent.document).append("""<div id="#{msg}">#{msg}</div>""")

child1_startup = ->
  pollFor(-> $('#begin')[0]).then(->
    Meteor.BrowserStore.set('foo', 1234)
  )
  message_parent('child1-awake')

child2_startup = ->
  Meteor.autorun ->
    if Meteor.BrowserStore.equals('foo', 1234)
      message_parent('child2-got-it')
  message_parent('child2-awake')
