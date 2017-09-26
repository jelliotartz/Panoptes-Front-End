React = require 'react'
{Link} = require 'react-router'
talkClient = require 'panoptes-client/lib/talk-client'
NewDiscussionForm = require '../talk/discussion-new-form'
QuickSubjectCommentForm= require '../talk/quick-subject-comment-form'
Loading = require '../components/loading-indicator'
SignInPrompt = require '../partials/sign-in-prompt'
alert = require('../lib/alert').default

module.exports = React.createClass
  displayName: 'SubjectCommentForm'

  contextTypes:
    router: React.PropTypes.object.isRequired

  componentDidMount: ->
    console.log('!!!!!!!!firing CDM in comment form!!!!!!!!')
    @getBoards()

  componentWillMount: ->
    Promise.all([@getBoards(), @getSubjectDefaultBoard()]).then =>
      @setState loading: false

  getInitialState: ->
    loading: true
    tab: 0

  getBoards: ->
    talkClient.type('boards').get(section: @props.section, subject_default: false).then (boards) =>
      @setState {boards}

  getSubjectDefaultBoard: ->
    talkClient.type('boards').get(section: @props.section, subject_default: true).then ([subjectDefaultBoard]) =>
      @setState {subjectDefaultBoard}

  onCreateDiscussion: (createdDiscussion) ->
    {owner, name} = @props.params
    board = createdDiscussion.board_id
    discussion = createdDiscussion.id
    @context.router.push "/projects/#{owner}/#{name}/talk/#{board}/#{discussion}"

  linkToClassifier: (text) ->
    [owner, name] = @props.project.slug.split('/')
    <Link to={"/projects/#{owner}/#{name}/classify"}>{text}</Link>

  popup: ->
    alert (resolve) -> <SignInPrompt onChoose={resolve} />

  loginPrompt: ->
    <p>
      Please{' '}
      <button className="link-style" type="button" onClick={@popup}>
        sign in
      </button>{' '}
      to contribute to subject discussions
    </p>

  notSetup: ->
    <p>There are no discussion boards setup for this project yet. Check back soon!</p>

  quickComment: ->
    console.log('hello from quick comment!!!!!!')
    console.log('!!!!!!!!!!!!!!@state.subjectDefaultBoard!!!!!!!!!!!')
    console.log(@state.subjectDefaultBoard)
    if @state.subjectDefaultBoard
      <QuickSubjectCommentForm {...@props} subject={@props.subject} user={@props.user} />
    else
      @notSetup() # there is no default board. therefore displaying the not setup message.
      # <p>
      #   There is no default board for subject comments setup yet, Please{' '}
      #   <button className="link-style" onClick={=> @setState(tab: 1)}>start a new discussion</button>{' '}
      #   or {@linkToClassifier('return to classifying')}
      # </p>

  startDiscussion: ->
    if @state.boards.length < 0
      @getBoards()

    <NewDiscussionForm
      user={@props.user}
      project={@props.project}
      subject={@props.subject}
      onCreateDiscussion={@onCreateDiscussion} />

    # console.log('hello from start discussion!!!!!!!!!!!!')
    # console.log(@state.boards)

    # if @state.boards not true
    #   @getSubjectDefaultBoard


  renderTab: ->
    console.log('hello from render tab!!!')
    console.log(@state.boards.length)

    if @state.boards.length > 0 # if @state.boards has any boards, render both quick comment and start discussion
      switch @state.tab
        when 0 then @quickComment()
        when 1 then @startDiscussion()
    else # if there are no additional boards set up, only render the quick comment tab
      @quickComment()



  render: ->
    return <Loading /> if @state.loading
    return @notSetup() unless @state.boards
    return @loginPrompt() unless @props.user

    <div>
      <div className="tabbed-content">
        <div className="tabbed-content-tabs">
          <div className="subject-page-tabs">
            <div className="tabbed-content-tab #{if @state.tab is 0 then 'active' else ''}" onClick={=> @setState({tab: 0})}>
              Add a note about this subject
            </div>

            <div className="tabbed-content-tab #{if @state.tab is 1 then 'active' else ''} #{if @state.boards.length < 1 then 'test'}" onClick={=> @setState({tab: 1})}>
              Start a new discussion
            </div>
          </div>
        </div>
      </div>

      {@renderTab()}
    </div>
