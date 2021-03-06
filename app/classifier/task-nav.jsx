import React from 'react';
import { Link } from 'react-router';
import Translate from 'react-translate-component';
import { getSessionID } from '../lib/session';
import tasks from './tasks';
import CacheClassification from '../components/cache-classification';
import GridTool from './drawing-tools/grid';
import { isFeedbackActive, isThereFeedback } from './feedback/helpers';

/* eslint-disable multiline-ternary, no-nested-ternary, react/jsx-no-bind */

const BackButtonWarning = () => {
  return (
    <p className="back-button-warning" >
      <Translate content="classifier.backButtonWarning" />
    </p>
  );
};

class TaskNav extends React.Component {
  constructor(props) {
    super(props);
    this.addAnnotationForTask = this.addAnnotationForTask.bind(this);
    this.completeClassification = this.completeClassification.bind(this);
    this.destroyCurrentAnnotation = this.destroyCurrentAnnotation.bind(this);
    this.warningToggleOn = this.warningToggleOn.bind(this);
    this.warningToggleOff = this.warningToggleOff.bind(this);
    this.state = {
      BackButtonWarning: false
    };
  }

  componentDidUpdate() {
    const { workflow, classification } = this.props;
    classification.annotations = classification.annotations ? classification.annotations : [];
    if (classification.annotations.length === 0) {
      this.addAnnotationForTask(workflow.first_task);
    }
  }
  // Next (or first question)
  addAnnotationForTask(taskKey) {
    const { workflow, classification } = this.props;
    const taskDescription = workflow.tasks[taskKey];
    let annotation = tasks[taskDescription.type].getDefaultAnnotation(taskDescription, workflow, tasks);
    annotation.task = taskKey;

    if (workflow.configuration.persist_annotations) {
      const cachedAnnotation = CacheClassification.isAnnotationCached(taskKey);
      if (cachedAnnotation) {
        annotation = cachedAnnotation;
      }
    }

    classification.annotations.push(annotation);
    classification.update('annotations');
  }

  // Done
  completeClassification() {
    const { workflow, classification } = this.props;
    if (workflow.configuration.persist_annotations) {
      CacheClassification.delete();
    }

    const currentAnnotation = classification.annotations[classification.annotations.length - 1];
    const currentTask = workflow.tasks[currentAnnotation.task];

    if (currentTask && currentTask.tools) {
      currentTask.tools.map((tool) => {
        if (tool.type === 'grid') {
          GridTool.mapCells(classification.annotations);
        }
      });
    }

    classification.update({
      completed: true,
      'metadata.session': getSessionID(),
      'metadata.finished_at': (new Date()).toISOString(),
      'metadata.viewport': {
        width: innerWidth,
        height: innerHeight
      }
    });

    if (currentAnnotation.shortcut) {
      this.addAnnotationForTask(currentTask.unlinkedTask);
      const newAnnotation = classification.annotations[classification.annotations.length - 1];
      newAnnotation.value = currentAnnotation.shortcut.value;
      delete currentAnnotation.shortcut;
    }
    this.props.completeClassification();
  }

  // Back
  destroyCurrentAnnotation() {
    const { workflow, classification } = this.props;
    const lastAnnotation = classification.annotations[classification.annotations.length - 1];

    classification.annotations.pop();
    classification.update('annotations');

    if (workflow.configuration.persist_annotations) {
      CacheClassification.update(lastAnnotation);
    }
  }

  warningToggleOn() {
    if (!this.props.workflow.configuration.persist_annotations) {
      this.setState({ backButtonWarning: true });
    }
  }

  warningToggleOff() {
    if (!this.props.workflow.configuration.persist_annotations) {
      this.setState({ backButtonWarning: false });
    }
  }

  render() {
    const completed = !!this.props.classification.completed;

    const task = this.props.task ? this.props.task : this.props.workflow.tasks[this.props.workflow.first_task];

    const disableTalk = this.props.classification.metadata.subject_flagged ||
    (isFeedbackActive(this.props.project) && isThereFeedback(this.props.subject, this.props.workflow));
    const visibleTasks = Object.keys(this.props.workflow.tasks).filter((key) => { return this.props.workflow.tasks[key].type !== 'shortcut'; });
    const TaskComponent = tasks[task.type];

    // Should we disable the "Back" button?
    const onFirstAnnotation = !completed && (this.props.classification.annotations.indexOf(this.props.annotation) === 0);

    // Should we disable the "Next" or "Done" buttons?
    let waitingForAnswer = this.props.disabled;
    if (TaskComponent && TaskComponent.isAnnotationComplete && this.props.annotation) {
      waitingForAnswer = !this.props.annotation.shortcut && !TaskComponent.isAnnotationComplete(task, this.props.annotation, this.props.workflow);
    }

    // Each answer of a single-answer task can have its own `next` key to override the task's.
    let nextTaskKey = '';
    if (TaskComponent === tasks.single && this.props.annotation) {
      const currentAnswer = task.answers[this.props.annotation.value];
      nextTaskKey = currentAnswer ? currentAnswer.next : '';
    } else {
      nextTaskKey = task.next;
    }

    if (nextTaskKey && !this.props.workflow.tasks[nextTaskKey]) {
      nextTaskKey = '';
    }

    // TODO: Actually disable things that should be.
    // For now we'll just make them non-mousable.
    const disabledStyle = {
      opacity: 0.5,
      pointerEvents: 'none'
    };

    return (
      <div>
        <nav className="task-nav">
          {(visibleTasks.length > 1) && !completed &&
            <button
              type="button"
              className="back minor-button"
              disabled={onFirstAnnotation}
              onClick={this.destroyCurrentAnnotation}
              onMouseEnter={this.warningToggleOn}
              onFocus={this.warningToggleOn}
              onMouseLeave={this.warningToggleOff}
              onBlur={this.warningToggleOff}
            >
              <Translate content="classifier.back" />
            </button>}
          {(!nextTaskKey && this.props.workflow.configuration.hide_classification_summaries && this.props.project && !disableTalk && !completed) &&
            <Link
              onClick={this.completeClassification}
              to={`/projects/${this.props.project.slug}/talk/subjects/${this.props.subject.id}`}
              className="talk standard-button"
              style={waitingForAnswer ? disabledStyle : {}}
            >
              <Translate content="classifier.doneAndTalk" />
            </Link>}
          {(nextTaskKey && this.props.annotation && !this.props.annotation.shortcut) ?
            <button
              type="button"
              className="continue major-button"
              disabled={waitingForAnswer}
              onClick={this.addAnnotationForTask.bind(this, nextTaskKey)}
            >
              <Translate content="classifier.next" />
            </button> : !completed ?
              <button
                type="button"
                className="continue major-button"
                disabled={waitingForAnswer}
                onClick={this.completeClassification}
              >
                {this.props.demoMode && <i className="fa fa-trash fa-fw" />}
                {this.props.classification.gold_standard && <i className="fa fa-star fa-fw" />}
                {' '}<Translate content="classifier.done" />
              </button> :
              null
          }
          {completed &&
            <Link
              onClick={this.props.nextSubject}
              to={`/projects/${this.props.project.slug}/talk/subjects/${this.props.subject.id}`}
              className="talk standard-button"
            >
              <Translate content="classifier.talk" />
            </Link>}
          {completed &&
            <button
              autoFocus={true}
              className="continue major-button"
              onClick={this.props.nextSubject}
            >
              <Translate content="classifier.next" />
            </button>}
          {this.props.children}
        </nav>
        {this.state.backButtonWarning && <BackButtonWarning />}
      </div>
    );
  }
}

TaskNav.propTypes = {
  annotation: React.PropTypes.shape({
    shortcut: React.PropTypes.object,
    value: React.PropTypes.any
  }),
  children: React.PropTypes.node,
  classification: React.PropTypes.shape({
    annotations: React.PropTypes.array,
    completed: React.PropTypes.bool,
    gold_standard: React.PropTypes.bool,
    id: React.PropTypes.string,
    metadata: React.PropTypes.object
  }),
  completeClassification: React.PropTypes.func,
  disabled: React.PropTypes.bool,
  nextSubject: React.PropTypes.func,
  demoMode: React.PropTypes.bool,
  project: React.PropTypes.shape({
    id: React.PropTypes.string,
    slug: React.PropTypes.string
  }),
  subject: React.PropTypes.shape({
    id: React.PropTypes.string
  }),
  task: React.PropTypes.shape({
    type: React.PropTypes.string
  }),
  workflow: React.PropTypes.shape({
    id: React.PropTypes.string,
    configuration: React.PropTypes.object,
    first_task: React.PropTypes.string,
    tasks: React.PropTypes.object
  })
};

TaskNav.defaultProps = {
  disabled: false
};

export default TaskNav;
