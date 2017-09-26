React = require 'react'
ReactDOM = require 'react-dom'
CommentBox = require './comment-box'
{getErrors} = require './lib/validations'
commentValidations = require './lib/comment-validations'
discussionValidations = require './lib/discussion-validations'
talkClient = require 'panoptes-client/lib/talk-client'
Loading = require '../components/loading-indicator'
projectSection = require '../talk/lib/project-section'

module.exports = React.createClass
  displayName: 'DiscussionNewForm'

  propTypes:
    boardId: React.PropTypes.number
    onCreateDiscussion: React.PropTypes.func
    subject: React.PropTypes.object # subject response

  getInitialState: ->
    discussionValidationErrors: []
    loading: false
    boards: []

  componentDidMount: ->
    console.log('!!!!!!!!!firing component did mount!!!!!!!!!')
    @updateBoards @props.subject

  componentWillReceiveProps: (newProps) ->
    console.log('!!!!!!!!!firing component will receive props!!!!!!!!!')
    @updateBoards newProps.subject if newProps.subject isnt @props.subject

  updateBoards: (subject) ->
    console.log('!!!!!!!!!!!!!!!!!update boards subject:!!!!!!!!!!!!!!!!!')
    console.log(subject)

    subject?.get 'project'
      .then (project) =>

        console.log('!!!!!!!!!!!!!!!project response: !!!!!!!!!!!!!!!!!')
        console.log(project)

        talkClient.type 'boards'
          .get
            section: projectSection(project)
            subject_default: false
          .then (boards) =>
            @setState {boards}

  discussionValidations: (commentBody) ->
    discussionTitle = ReactDOM.findDOMNode(@).querySelector('.new-discussion-title').value
    commentErrors = getErrors(commentBody, commentValidations)
    discussionErrors = getErrors(discussionTitle, discussionValidations)

    discussionValidationErrors = commentErrors.concat(discussionErrors)

    @setState {discussionValidationErrors}
    !!discussionValidationErrors.length

  onSubmitDiscussion: (e, commentText, subject) ->
    @setState loading: true
    form = ReactDOM.findDOMNode(@).querySelector('.talk-board-new-discussion')
    titleInput = form.querySelector('input[type="text"]')


    title = titleInput.value

    console.log('!!!!!!!!!!!!!!!!!on submit discussion\'s subject:!!!!!!!!!!!!!!!!!')
    console.log(subject)

    user_id = @props.user.id

    console.log('!!!!!!!!!!!!!!!!!@board_id:!!!!!!!!!!!!!!!!!')
    console.log(@board_id)

    board_id = @props.boardId ? +form.querySelector('label > input[type="radio"]:checked').value

    console.log('!!!!!!!!!!!!!!!!!do you understand that i\'m trying to set @board_id? :!!!!!!!!!!!!!!!!!')
    console.log(@board_id)

    body = commentText
    focus_id = subject?.id
    focus_type = 'Subject' if !!focus_id

    comment = if !!focus_id
      {user_id, body, focus_id, focus_type}
    else
      {user_id, body}

    comments = [comment]
    discussion = {title, user_id, board_id, comments}

    talkClient.type('discussions').create(discussion).save()
      .then (discussion) =>
        @setState loading: false
        titleInput.value = ''
        @props.onCreateDiscussion?(discussion)

  boardRadio: (board, i) ->
    <label key={board.id}>
      <input
        type="radio"
        name="board"
        defaultChecked={i is 0}
        value={board.id} />
      {board.title}
    </label>

  render: ->
    <div className="discussion-new-form">
      <div className="talk-board-new-discussion">
        <h2>Create a discussion +</h2>
        {if not @props.boardId
          <div>
            <h2>Board</h2>
            {@state.boards.map @boardRadio}
          </div>
          }
        <input
          className="new-discussion-title"
          type="text"
          placeholder="Discussion Title"/>
        <CommentBox
          user={@props.user}
          project={@props.project}
          header={null}
          validationCheck={@discussionValidations}
          validationErrors={@state.discussionValidationErrors}
          submitFeedback={"Discussion successfully created"}
          placeholder={"""Add a comment here to start the discussion.
          This comment will appear at the start of the discussion."""}
          onSubmitComment={@onSubmitDiscussion}
          logSubmit={true}
          subject={@props.subject}
          submit="Create Discussion"/>
        {if @state.loading then <Loading />}
      </div>
    </div>
