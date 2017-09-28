import React from 'react';
import counterpart from 'counterpart';
import Translate from 'react-translate-component';
import { IndexLink, Link } from 'react-router';
import { Helmet } from 'react-helmet';
import ChangeListener from '../components/change-listener';

counterpart.registerTranslations('en', {
  userAdminPage: {
    header: 'Admin',
    nav: {
      createAdmin: 'Manage Users',
      projectStatus: 'Set Project Status',
      grantbot: 'Grantbot',
      organizationStatus: 'Set Organization Status'
    }
  }
});

class AdminPage extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <section className="admin-page-content">
        <Helmet title={counterpart('userAdminPage.header')} />
        <div className="secondary-page admin-page">
          <h2><Translate content="userAdminPage.header" /></h2>
          <div className="admin-content">
            <aside className="secondary-page-side-bar admin-side-bar">
              <nav>
                <IndexLink
                  to="/admin"
                  type="button"
                  className="secret-button admin-button"
                  activeClassName="active"
                >
                  <Translate content="userAdminPage.nav.createAdmin" />
                </IndexLink>
                <Link
                  to="/admin/project_status"
                  type="button"
                  className="secret-button admin-button"
                  activeClassName="active"
                >
                  <Translate content="userAdminPage.nav.projectStatus" />
                </Link>
                <Link
                  to="/admin/grantbot"
                  type="button"
                  className="secret-button admin-button"
                  activeClassName="active"
                >
                  <Translate content="userAdminPage.nav.grantbot" />
                </Link>
                <Link
                  to="/admin/organization-status"
                  type="button"
                  className="secret-button admin-button"
                  activeClassName="active"
                >
                  <Translate content="userAdminPage.nav.organizationStatus" />
                </Link>
              </nav>
            </aside>
            <section className="admin-tab-content">
              {React.cloneElement(this.props.children, this.props)}
            </section>
          </div>
        </div>
      </section>
    )
  }
}


class AdminPageWrapper extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    {this.props.user && this.props.user.admin &&
      (<ChangeListener target={this.props.user}>
        {React.cloneElement(AdminPage, this.props)}
      </ChangeListener>)}

    {this.props.user &&
      (<div className="content-container">
        <p>You are not an administrator</p>
      </div>)}

    (<div className="content-container">
        <p>You’re not signed in.</p>
      </div>);

  }
}

export default AdminPageWrapper;

