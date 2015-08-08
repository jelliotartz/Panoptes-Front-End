React = require 'react'
ChangeListener = require '../components/change-listener'
SubjectAnnotator = require './subject-annotator'
ClassificationSummary = require './classification-summary'
{Link} = require 'react-router'
tasks = require './tasks'
drawingTools = require './drawing-tools'

unless process.env.NODE_ENV is 'production'
  mockData = require './mock-data'

Classifier = React.createClass
  displayName: 'Classifier'

  _lastAnnotationAndTool: ''

  getDefaultProps: ->
    user: null
    if mockData?
      {workflow, subject, classification} = mockData
    workflow: workflow
    subject: subject
    classification: classification
    onLoad: Function.prototype

  getInitialState: ->
    subjectLoading: false
    showingExpertClassification: false
    selectedExpertAnnotation: -1

  componentDidMount: ->
    @loadSubject @props.subject
    @prepareToClassify @props.classification

  componentWillReceiveProps: (nextProps) ->
    if nextProps.subject isnt @props.subject
      @loadSubject subject
    if nextProps.classification isnt @props.classification
      @prepareToClassify nextProps.classification

  loadSubject: (subject) ->
    @setState subjectLoading: true
    # TODO: Pre-cache subject images here and change loading state back.

  prepareToClassify: (classification) ->
    setTimeout => # TODO: Why is this here?
      classification.annotations ?= []
      if classification.annotations.length is 0
        @addAnnotationForTask @props.workflow.first_task

  render: ->
    <ChangeListener target={@props.classification}>{=>
      currentClassification = if @state.showingExpertClassification
        @props.subject.expert_classification_data
      else
        @props.classification

      if currentClassification is @props.classification and not @props.classification.completed
        currentAnnotation = currentClassification.annotations[currentClassification.annotations.length - 1]
        currentTask = @props.workflow.tasks[currentAnnotation?.task]

      <div className="classifier">
        <SubjectAnnotator
          user={@props.user}
          project={@props.project}
          subject={@props.subject}
          workflow={@props.workflow}
          classification={currentClassification}
          annotation={currentAnnotation}
          onLoad={@handleSubjectImageLoad}
        />

        <div className="task-area">
          {if currentTask?
            @renderTask currentClassification, currentAnnotation, currentTask
          else # Classification is complete.
            @renderSummary currentClassification}
        </div>
      </div>
    }</ChangeListener>

  renderTask: (classification, annotation, task) ->
    TaskComponent = tasks[task.type]

    onFirstAnnotation = classification.annotations.indexOf(annotation) is 0

    if TaskComponent.isAnnotationComplete?
      waitingForAnswer = not TaskComponent.isAnnotationComplete task, annotation

    if TaskComponent is tasks.single
      currentAnswer = task.answers?[annotation.value]
    # If the next task key exists, make sure the task it points to actually exists.
    nextTaskKey = if currentAnswer? and @props.workflow.tasks[currentAnswer.next]?
      currentAnswer.next
    else if @props.workflow.tasks[task.next]?
      task.next

    # TODO: Actually disable things that should be.
    disabledStyle =
      opacity: 0.5
      pointerEvents: 'none'

    <div className="task-container" style={disabledStyle if @state.subjectLoading}>
      <TaskComponent task={task} annotation={annotation} onChange={@updateAnnotations.bind this, classification} />

      <hr />

      <nav className="task-nav">
        <button type="button" className="back minor-button" disabled={onFirstAnnotation} onClick={@destroyCurrentAnnotation}>Back</button>
        {if nextTaskKey
          <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@addAnnotationForTask.bind this, nextTaskKey}>Next</button>
        else
          <button type="button" className="continue major-button" disabled={waitingForAnswer} onClick={@completeClassification}>Done</button>}
      </nav>
    </div>

  renderSummary: (classification) ->
    <div>
      Thanks!

      {if @props.subject.expert_classification_data?
        <div className="has-expert-classification">
          Expert classification available.
          {if @state.showingExpertClassification
            <button type="button" onClick={@toggleExpertClassification.bind this, false}>Hide</button>
          else
            <button type="button" onClick={@toggleExpertClassification.bind this, true}>Show</button>}
        </div>}

      {if @state.showingExpertClassification
        'Expert classification:'
      else
        'Your classification:'}
      <ClassificationSummary workflow={@props.workflow} classification={classification} />

      <hr />

      <nav className="task-nav">
        {if @props.owner? and @props.project?
          [ownerName, name] = @props.project.slug.split('/')
          <Link onClick={@props.onClickNext} to="project-talk-subject" params={owner: ownerName, name: name, id: @props.subject.id} className="talk standard-button">Talk</Link>}
        <button type="button" className="continue major-button" onClick={@props.onClickNext}>Next</button>
      </nav>
    </div>

  handleSubjectImageLoad: (e, frameIndex) ->
    @setState subjectLoading: false

    {naturalWidth, naturalHeight, clientWidth, clientHeight} = e.target

    changes = {}
    changes["metadata.subject_dimensions.#{frameIndex}"] = {naturalWidth, naturalHeight, clientWidth, clientHeight}

    @props.classification.update changes

    @props.onLoad? arguments...

  updateAnnotations: (classification) ->
    classification.update 'annotations'
    @checkToolChange classification

  checkToolChange: (classification) ->
    lastAnnotationIndex = classification.annotations.length - 1
    lastAnnotation = classification.annotations[lastAnnotationIndex]
    if @props.workflow.tasks[lastAnnotation.task].type is 'drawing'
      toolIdentifier = "#{lastAnnotationIndex}-#{lastAnnotation._toolIndex}"

      if Array.isArray(lastAnnotation.value) and toolIdentifier isnt @_lastAnnotationAndTool
        @handleToolChange lastAnnotation, @_lastAnnotationAndTool.split('-').pop() ? '-1'
        @_lastAnnotationAndTool = toolIdentifier

  handleToolChange: (annotation, oldToolIndex) ->
    lastMark = annotation.value[annotation.value.length - 1]
    if lastMark?
      ToolComponent = drawingTools[@props.workflow.tasks[annotation.task].tools[oldToolIndex]?.type]
      if ToolComponent?
        if ToolComponent.isComplete? and not ToolComponent.isComplete lastMark
          ToolComponent.forceComplete? lastMark

  destroyCurrentAnnotation: ->
    @props.classification.annotations.pop()
    @props.classification.update 'annotations'

  addAnnotationForTask: (taskKey) ->
    taskDescription = @props.workflow.tasks[taskKey]
    annotation = tasks[taskDescription.type].getDefaultAnnotation()
    annotation.task = taskKey
    @props.classification.annotations.push annotation
    @props.classification.update 'annotations'

  completeClassification: ->
    @props.classification.update
      completed: true
      'metadata.finished_at': (new Date).toISOString()
      'metadata.viewport':
        width: innerWidth
        height: innerHeight

    @props.onComplete?()

  toggleExpertClassification: (value) ->
    @setState showingExpertClassification: value


module.exports = React.createClass
  displayName: 'ClassifierWrapper'

  getDefaultProps: ->
    user: null
    classification: mockData?.classification ? {}
    onLoad: Function.prototype
    onComplete: Function.prototype
    onClickNext: Function.prototype

  getInitialState: ->
    workflow: null
    subject: null

  componentDidMount: ->
    @loadClassification @props.classification

  componentWillReceiveProps: (nextProps) ->
    unless nextProps.classification is @props.classification
      @loadClassification nextProps.classification

  loadClassification: (classification) ->
    @setState
      workflow: null
      subject: null

    # TODO: These underscored references are temporary stopgaps.

    Promise.resolve(classification._workflow ? classification.get 'workflow').then (workflow) =>
      @setState {workflow}

    Promise.resolve(classification._subjects ? classification.get 'subjects').then ([subject]) =>
      # We'll only handle one subject per classification right now.
      # TODO: Support multi-subject classifications in the future.
      @setState {subject}

  render: ->
    if @state.workflow? and @state.subject?
      <Classifier {...@props} workflow={@state.workflow} subject={@state.subject} />
    else
      <span>Loading classifier...</span>
