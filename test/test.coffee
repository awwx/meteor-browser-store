if Meteor.isClient

  switch window.location.pathname
    when '/'
      window.name = 'parent'
      Template.renderPage.showHome = -> true
      Meteor.startup -> parent_startup()
    when '/test1/child1'
      window.name = 'child1'
      Template.renderPage.showChild1 = -> true
      Meteor.startup -> child1_startup()
    when '/test1/child2'
      window.name = 'child2'
      Template.renderPage.showChild2 = -> true
      Meteor.startup -> child2_startup()

  _when = window.when

  add_event = (type, handler) ->
    if window.addEventListener
      window.addEventListener type, handler, false
    else if window.attachEvent
      window.attachEvent type, handler

  ok_to_start_children = _when.defer()
  home_template_created = _when.defer()

  Session.set('ready', false)
  Session.set('done', false)

  Template.test1_home.ready = -> Session.get('ready')
  Template.test1_home.done  = -> Session.get('done')

  created_already = false
  Template.test1_home.created = ->
    throw new Error('oops already created') if created_already
    created_already = true
    home_template_created.resolve()

  _when.join(home_template_created, ok_to_start_children)
  .then ->
    $('#iframes').append('''
      <iframe id="child1" src="/test1/child1"></iframe>
      <iframe id="child2" src="/test1/child2"></iframe>
    ''')

  child2_got_it = ->
    Session.set('done', true)

  parent_startup = ->
    child1_awake = _when.defer()
    child2_awake = _when.defer()
    add_event(
      'message',
      ((event) ->
        switch event.data
          when 'child1 is awake' then child1_awake.resolve()
          when 'child2 is awake' then child2_awake.resolve()
          when 'child2 got it'   then child2_got_it()
      )
    )
    _when.join(child1_awake, child2_awake)
    .then(->
      $('#child1')[0].contentWindow.postMessage 'begin', '*'
    )

    Meteor.LocalStore.clear()
    ok_to_start_children.resolve()

  child1_begin = ->
    Meteor.LocalStore.set('foo', 1234)

  child1_startup = ->
    add_event(
      'message',
      ((event) ->
        switch event.data
          when 'begin' then child1_begin()
      )
    )

    window.parent.postMessage 'child1 is awake', '*'

  child2_startup = ->
    Meteor.autorun ->
      if Meteor.LocalStore.equals('foo', 1234)
        window.parent.postMessage 'child2 got it', '*'

    window.parent.postMessage 'child2 is awake', '*'
