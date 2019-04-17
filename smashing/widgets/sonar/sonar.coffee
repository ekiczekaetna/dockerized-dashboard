class Dashing.Sonar extends Dashing.Widget
  ready: ->
    if @get('unordered')
      # $(@node).fadeOut().css('background-color', @get('bgColor')).fadeIn()
      $(@node).find('ol').remove()
    else
      # $(@node).fadeOut().css('background-color', @get('bgColor')).fadeIn()
      $(@node).find('ul').remove()

  onData: (data) ->
    if data.sonarHealth
    # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bstatus-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.sonarHealth}"
