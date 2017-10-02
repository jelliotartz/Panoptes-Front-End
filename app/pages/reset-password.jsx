import React, { PropTypes } from 'react'; // why import component as separate 'object?'
import auth from 'panoptes-client/lib/auth';
import alert from '../lib/alert';
import LoginDialog from '../partials/login-dialog';
import Translate from 'react-translate-component';

class ResetPasswordPage extends React.Component {
  constructor() {
    super();

    this.state = {
      inProgress: false,
      resetSuccess: false,
      resetError: null,
      emailSuccess: false,
      emailError: false,
      emailIsValid: false
    };

    this.handlePasswordResetSubmit = this.handlePasswordResetSubmit.bind(this);
    this.handleEmailSubmit = this.handleEmailSubmit.bind(this);
    this.handleEmailChange = this.handleEmailChange.bind(this);
  }

  handleEmailChange(event) {
    this.setState({ emailIsValid: event.target.checkValidity() });
  }

  handleEmailSubmit(event) {
    event.preventDefault(); // is this needed?

    this.setState({
      inProgress: true,
      emailSuccess: false,
      emailError: null
    });

    const email = this.email.value;

    auth.requestPasswordReset({ email })
      .then(() => {
        this.setState({ emailSuccess: true });
      })
      .catch((error) => {
        this.setState({ emailError: true });
      })
      .then(() => {
        this.setState({ inProgress: false }); // better way than all these set states?
      });
  }

  handlePasswordResetSubmit(event) {
    event.preventDefault(); // is this needed?

    this.setState({
      inProgress: true,
      resetSuccess: false,
      resetError: null
    });

    const token = this.props.location.query.reset_password_token;
    const password = this.password.value;
    const confirmation = this.confirmation.value;

    auth.resetPassword({ password, confirmation, token })
      .then(() => {
        this.setState({ resetSuccess: true });
        alert(resolve => <LoginDialog onSuccess={resolve} />);
      })
      .catch((error) => {
        this.setState({ resetError: true });
      })
      .then(() => {
        this.setState({ inProgress: false }); // better way than all these set states?
      });
  }

  // TODO: move the p tag text into translate elements; maybe replace with labels?
  renderNewPasswordForm() {
    return (
      <form method="POST" onSubmit={this.handlePasswordResetSubmit}>
        <Translate component="p" content="resetPassword.newPasswordFormDialog" />
        <p>
          New password:<br />
          <input
            ref={(input) => { this.password = input; }}
            type="password"
            className="standard-input"
            size="20"
          />
        </p>

        <p>
          Again, to confirm:<br />
          <input
            ref={(input) => { this.confirmation = input; }}
            type="password"
            className="standard-input"
            size="20"
          />
        </p>

        <p>
          <button
            type="submit"
            className="standard-button"
            disabled={this.state.resetError || this.state.resetSuccess}
          >
            Submit
          </button>{' '}

          {this.state.inProgress &&
            <i className="fa fa-spinner fa-spin form-help" />}

          {this.state.resetSuccess &&
            <i className="fa fa-check-circle form-help success" />}

          {this.state.resetError &&
            <Translate
              className="form-help error"
              component="small"
              content="resetPassword.resetError"
            />}
        </p>
      </form>
    );
  }

  renderSubmitEmailForm() {
    if (this.props.user) {
      alert((resolve) =>
        <Translate
          onSuccess={resolve}
          content="resetPassword.loggedInDialog"
        />
      );
      this.context.router.push('/');
    }

    return (
      <form onSubmit={this.handleEmailSubmit}>
        <Translate component="p" content="resetPassword.enterEmailDialog" />
        <p>
          <input
            type="email"
            ref={(input) => { this.email = input; }}
            required={true}
            onChange={this.handleEmailChange}
            className="standard-input"
            size="50"
          />
        </p>
        <p>
          <button
            type="submit"
            className="standard-button"
            disabled={!this.state.emailIsValid}
          >
            Submit
          </button>{' '}

          {this.state.inProgress &&
            <i className="fa fa-spinner fa-spin form-help" />}

          {this.state.emailSuccess &&
            <i className="fa fa-check-circle form-help success" />}
        </p>

        {this.state.emailSuccess &&
          <Translate component="p" content="resetPassword.emailSuccess" />}

        {this.state.emailError &&
          <Translate
            className="form-help error"
            component="small"
            content="resetPassword.emailError"
          />}
      </form>
    );
  }

  render() {
    return (
      <div className="centered-grid">

        {this.props.location.query && !this.props.location.query.reset_password_token &&
          this.renderSubmitEmailForm()}

        {this.props.location.query && this.props.location.query.reset_password_token && this.state.resetSuccess &&
          this.context.router.push('/projects')}

        {this.props.location.query && this.props.location.query.reset_password_token && !this.state.resetSuccess &&
          this.renderNewPasswordForm()}

      </div>
    );
  }
}

ResetPasswordPage.propTypes = {
  location: PropTypes.shape({
    query: PropTypes.shape({
      reset_password_token: PropTypes.string
    })
  }),
  user: PropTypes.shape({
    display_name: PropTypes.string // how to deal with user prop type and linter?
  })
};

ResetPasswordPage.defaultProps = {
  location: {
    query: {
      reset_password_token: null // is this ok/not a security risk?
    }
  },
  user: null
};

ResetPasswordPage.contextTypes = {
  router: React.PropTypes.object.isRequired
};

export default ResetPasswordPage;
