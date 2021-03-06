React = require 'react'
{ Helmet } = require 'react-helmet'
apiClient = require 'panoptes-client/lib/api-client'
{ Split } = require('seven-ten')
counterpart = require 'counterpart'
isAdmin = require '../../lib/is-admin'
ProjectTranslations = require('./project-translations').default
{ connect } = require 'react-redux';
{ bindActionCreators } = require 'redux';
translationActions  = require '../../redux/ducks/translations';
ProjectPage = require('./project-page').default;

counterpart.registerTranslations 'en', require('../../locales/en').default
counterpart.registerTranslations 'it', require('../../locales/it').default
counterpart.registerTranslations 'es', require('../../locales/es').default
counterpart.registerTranslations 'nl', require('../../locales/nl').default
counterpart.setFallbackLocale 'en'


ProjectPageController = React.createClass
  displayName: 'ProjectPageController'

  contextTypes:
    geordi: React.PropTypes.object
    initialLoadComplete: React.PropTypes.bool
    router: React.PropTypes.object.isRequired

  propTypes:
    params: React.PropTypes.object
    user: React.PropTypes.object

  getDefaultProps: ->
    params: {}
    user: null

  getInitialState: ->
    background: null
    error: null
    guide: null
    guideIcons: {}
    loading: false
    loadingSelectedWorkflow: false
    organization: null
    owner: null
    preferences: null
    project: null
    projectAvatar: null
    projectIsComplete: false
    projectRoles: null
    splits: null
    workflow: null

  _listenedToPreferences: null

  _boundForceUpdate: null

  componentWillMount: ->
    { actions } = @props
    actions.translations.setLocale(@props.location.query.language) if @props.location.query.language

  componentDidMount: ->
    @_boundForceUpdate = @forceUpdate.bind this
    @fetchProjectData @props.params.owner, @props.params.name, @props.user if @context.initialLoadComplete
    @setupSplits()

  componentWillReceiveProps: (nextProps, nextContext) ->
    {owner, name} = nextProps.params
    pathChanged = owner isnt @props.params.owner or name isnt @props.params.name
    userChanged = nextContext.initialLoadComplete and nextProps.user isnt @props.user

    # Wait until we know if there's a user
    if pathChanged or userChanged or nextContext.initialLoadComplete and @state.project is null
      @fetchProjectData owner, name, nextProps.user unless @state.loading
      @setupSplits nextProps

  componentWillUpdate: (nextProps, nextState) ->
    if nextState.preferences?.preferences?.selected_workflow? and @state.workflow?
      if nextState.preferences?.preferences.selected_workflow isnt @state.workflow.id
        @getSelectedWorkflow(nextState.project, nextState.preferences) unless nextState.loadingSelectedWorkflow

  componentWillUnmount: ->
    Split.clear()

  setupSplits: (props = @props) ->
    user = props.user
    {owner, name} = props.params

    if user
      Split.load("#{owner}/#{name}").then (splits) =>
        @setState {splits}
        return unless splits
        for split of splits
          continue unless splits[split].state == 'active'
          @context.geordi?.remember experiment: splits[split].name
          @context.geordi?.remember cohort: splits[split].variant?.name
          break
    else
      Split.clear()
      @setState { splits: null }
      @context.geordi?.forget ['experiment','cohort']

  fetchProjectData: (ownerName, projectName, user) ->
    @setState({
      error: null,
      loading: true,
      preferences: null,
    })

    slug = ownerName + '/' + projectName

    apiClient.type('projects').get({ slug, include: 'avatar,background,owners' })
      .then ([project]) =>
        @setState {project}

        if project?
          # Use apiClient with cached resources from include to get out of cache
          awaitBackground = apiClient.type('backgrounds').get(project.links.background.id).catch((error) => [])

          if project.links?.organization?
            awaitOrganization = project.get('organization', { listed: true })
              .catch((error) => [])
              .then((response) => if response?.display_name then response else null)
          else
            awaitOrganization = Promise.resolve(null)

          awaitOwner = apiClient.type('users').get(project.links.owner.id).catch((error) => console.error(error))

          awaitPages = project.get('pages').catch((error) => []) # does not appear in project links?

          awaitProjectAvatar = apiClient.type('avatars').get(project.links.avatar.id).catch((error) => null)

          awaitProjectCompleteness = Promise.resolve(project.completeness is 1.0)

          awaitProjectRoles = project.get('project_roles', { page_size: 50 }).catch((error) => console.error(error))

          awaitPreferences = @getUserProjectPreferences(project, user)

          Promise.all([
            awaitBackground,
            awaitOrganization,
            awaitOwner,
            awaitPages,
            awaitProjectAvatar,
            awaitProjectCompleteness,
            awaitProjectRoles,
            awaitPreferences,
            this.props.actions.translations.load('project', project.id, this.props.translations.locale)
          ]).then(([background, organization, owner, pages, projectAvatar, projectIsComplete, projectRoles, preferences]) =>
              @setState({ background, organization, owner, pages, projectAvatar, projectIsComplete, projectRoles, preferences })
              @getSelectedWorkflow(project, preferences)
              @loadFieldGuide(project.id)
              this.props.actions.translations.loadTranslations('project_page', pages.map((page) => page.id), this.props.translations.locale)
            ).catch((error) => @setState({ error }); console.error(error); );

        else
          @setState
            background: null
            error: new Error 'NOT_FOUND'
            organization: null
            owner: null
            pages: null
            preferences: null
            projectAvatar: null
            projectIsComplete: false
            projectRoles: null
            workflow: null

      .catch (error) =>
        @setState {error}

      .then =>
        @setState loading: false

  getUserProjectPreferences: (project, user) ->
    @listenToPreferences null

    userPreferences = if user?
      user.get 'project_preferences', project_id: project.id
        .then ([preferences]) =>
          preferences ? newPreferences = apiClient.type('project_preferences').create({
            links: {
              project: project.id
            },
            preferences: {}
          }).save().catch (error) =>
            console.warn error.message
    else
      Promise.resolve apiClient.type('project_preferences').create
        id: 'GUEST_PREFERENCES_DO_NOT_SAVE'
        links:
          project: project.id
        preferences: {}

    userPreferences
      .then((preferences) =>
        @listenToPreferences preferences
      )
      .catch (error) =>
        console.warn error.message

  getSelectedWorkflow: (project, preferences) ->
    @setState({ loadingSelectedWorkflow: true })
    # preference workflow query by admin/owner/collab, then workflow query if in project settings, then user selected workflow, then project owner set workflow, then default workflow
    # if none of those are set, select random workflow
    activeFilter = true
    if @props.location.query?.workflow? and @checkUserRoles(project, @props.user)
      selectedWorkflowID = @props.location.query.workflow
      activeFilter = false
      unless preferences?.preferences.selected_workflow is selectedWorkflowID
        @handlePreferencesChange('preferences.selected_workflow', selectedWorkflowID)
    else if @props.location.query?.workflow? and 'allow workflow query' in project?.experimental_tools
      selectedWorkflowID = @props.location.query.workflow
      unless preferences?.preferences.selected_workflow is selectedWorkflowID
        @handlePreferencesChange('preferences.selected_workflow', selectedWorkflowID)
    else if preferences?.preferences.selected_workflow?
      selectedWorkflowID = preferences?.preferences.selected_workflow
    else if preferences?.settings?.workflow_id?
      selectedWorkflowID = preferences?.settings.workflow_id
    else if project.configuration?.default_workflow?
      selectedWorkflowID = project.configuration?.default_workflow
    else
      selectedWorkflowID = @selectRandomWorkflow(project)

    @getWorkflow(selectedWorkflowID, activeFilter)

  selectRandomWorkflow: (project) ->
    linkedActiveWorkflows = project.links.active_workflows
    if linkedActiveWorkflows?.length > 0
      randomIndex = Math.floor Math.random() * linkedActiveWorkflows.length
      # console.log 'Chose random workflow', linkedActiveWorkflows[randomIndex]
      linkedActiveWorkflows[randomIndex]
    else
      @workflowSelectionErrorHandler()


  getWorkflow: (selectedWorkflowID, activeFilter = true) ->
    { actions, translations } = this.props;
    query =
      id: "#{selectedWorkflowID}",
      project_id: @state.project.id
    if activeFilter
      query['active'] = true
    apiClient.type('workflows').get(query)
      .catch (error) =>
        if error.status is 404
          @clearInactiveWorkflow(selectedWorkflowID)
            .then(@getSelectedWorkflow(@state.project, @state.preferences))
        else
          console.error error
          @setState({ error: error, loadingSelectedWorkflow: false })
      .then ([workflow]) =>
        if workflow
          @setState({ loadingSelectedWorkflow: false, workflow })
          actions.translations.load('workflow', workflow.id, translations.locale)
        else
          console.log "No workflow #{selectedWorkflowID} for project #{@state.project.id}"
          if selectedWorkflowID is @state.project.configuration?.default_workflow
            # If a project still has an inactive workflow set as a default workflow prior to this being fix in the lab.
            # Don't try again and get caught in a loop
            @workflowSelectionErrorHandler()
          else
            if @props.location.query?.workflow?
              @context.router.push "/projects/#{@state.project.slug}/classify"
            @clearInactiveWorkflow(selectedWorkflowID)
              .then(@getSelectedWorkflow(@state.project, @state.preferences))
      .catch (error) => 
        console.warn error.message

  clearInactiveWorkflow: (selectedWorkflowID) ->
    preferences = @state.preferences
    selectedWorkflow = preferences.preferences.selected_workflow
    projectSetWorkflow = preferences.settings?.workflow_id

    if selectedWorkflowID is preferences.preferences.selected_workflow
      preferences.update 'preferences.selected_workflow': undefined
      preferences.save().catch (error) =>
        console.warn error.message
    else if selectedWorkflowID is preferences.settings?.workflow_id
      preferences.update 'settings.workflow_id': undefined
      preferences.save().catch (error) =>
        console.warn error.message
    else
      Promise.resolve({})

  workflowSelectionErrorHandler: () ->
    throw new Error "No active workflows for project #{@state.project.id}"
    @state.project.uncacheLink 'workflows'

  checkUserRoles: (project, user) ->
    currentUserRoleSets = @state.projectRoles.filter((roleSet) => roleSet.links.owner.id is user?.id)
    roles = currentUserRoleSets[0]?.roles or []

    isAdmin() or 'owner' in roles or 'collaborator' in roles or 'tester' in roles

  listenToPreferences: (preferences) ->
    @_listenedToPreferences?.stopListening 'change', @_boundForceUpdate
    preferences?.listen 'change', @_boundForceUpdate
    @_listenedToPreferences = preferences

  handlePreferencesChange: (key, value) ->
    changes = {}
    changes[key] = value
    if @state.preferences
      @state.preferences.update changes
      if @props.user?
        @state.preferences.save()

  loadFieldGuide: (projectId) ->
    apiClient.type('field_guides').get(project_id: projectId).then ([guide]) =>
      { actions, translations } = this.props;
      @setState {guide}
      actions.translations.load('field_guide', guide?.id, translations.locale)
      guide?.get('attached_images', page_size: 100)?.then (images) =>
        guideIcons = {}
        for image in images
          guideIcons[image.id] = image
        @setState {guideIcons}

  render: ->
    slug = @props.params.owner + '/' + @props.params.name
    betaApproved = @state.project?.beta_approved

    <div className="project-page-wrapper">
      <Helmet title="#{@state.project?.display_name ? counterpart 'loading'}" />
      {if betaApproved
        <div className="beta-border"></div>}

      {if @state.project? and @state.owner?
        <ProjectTranslations
          project={@state.project}
        >
          <ProjectPage
            {...@props}
            background={@state.background}
            guide={@state.guide}
            guideIcons={@state.guideIcons}
            loading={@state.loading}
            loadingSelectedWorkflow={@state.loadingSelectedWorkflow}
            onChangePreferences={@handlePreferencesChange}
            organization={@state.organization}
            owner={@state.owner}
            pages={@state.pages}
            preferences={@state.preferences}
            project={@state.project}
            projectAvatar={@state.projectAvatar}
            projectIsComplete={@state.projectIsComplete}
            projectRoles={@state.projectRoles}
            splits={@state.splits}
            workflow={@state.workflow}
          />
        </ProjectTranslations>

      else if @state.loading
        <div className="content-container">
          <p>
            Loading{' '}
            <strong>{slug}</strong>...
          </p>
        </div>

      else if @state.error?
        if @state.error.message is 'NOT_FOUND'
          <div className="content-container">
            <p>Project <code>{slug}</code> not found.</p>
            <p>If you're sure the URL is correct, you might not have permission to view this project.</p>
          </div>
        else
          <div className="content-container">
            <p>
              There was an error retrieving project{' '}
              <strong>{slug}</strong>.
            </p>
            <p>
              <code>{@state.error.toString()}</code>
            </p>
          </div>}
    </div>

mapStateToProps = (state) -> ({
  translations: state.translations
});

mapDispatchToProps = (dispatch) -> ({
  actions: {
    translations: bindActionCreators(translationActions, dispatch)
  }
});

module.exports = {
    default: connect(mapStateToProps, mapDispatchToProps, null, { pure: false })(ProjectPageController)
    ProjectPageController
  }
