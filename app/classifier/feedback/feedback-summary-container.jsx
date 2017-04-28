import React, { PropTypes } from 'react';
import counterpart from 'counterpart';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import FeedbackSummary from './feedback-summary';
import * as feedbackActions from '../../redux/ducks/feedback';
import processSingleFeedback from './process-feedback-single';
import processDrawingFeedback from './process-feedback-drawing';

const feedbackTypes = {
  single: processSingleFeedback,
  drawing: processDrawingFeedback
};

class FeedbackSummaryContainer extends React.Component {
  constructor(props) {
    super(props);
    this.generateFeedbackItems = this.generateFeedbackItems.bind(this);
  }

  componentWillMount() {
    this.generateFeedbackItems();
  }

  componentWillUnmount() {
    this.props.actions.feedback.clearFeedback();
  }

  render() {
    return (this.props.feedback.length) ? <FeedbackSummary feedback={this.props.feedback} /> : null;
  }

  generateFeedbackItems() {
    const { actions, classification, subject, workflow } = this.props;
    const feedbackItems = classification.annotations.reduce((allFeedback, annotation) => {
      const props = {
        annotation,
        subject,
        task: workflow.tasks[annotation.task],
      };
      return allFeedback.concat(feedbackTypes[props.task.type](props));
    }, []);
    actions.feedback.setFeedback(feedbackItems);
  }
}

FeedbackSummaryContainer.propTypes = {
  actions: PropTypes.object,
  classification: PropTypes.object,
  feedback: PropTypes.array,
  subject: PropTypes.object,
  workflow: PropTypes.object,
};

const mapStateToProps = (state) => ({
  feedback: state.feedback,
});

const mapDispatchToProps = (dispatch) => ({
  actions: {
    feedback: bindActionCreators(feedbackActions, dispatch),
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(FeedbackSummaryContainer);
