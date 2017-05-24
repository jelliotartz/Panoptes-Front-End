import React from 'react';
import ProjectCardList from '../projects/project-card-list';
import OrganizationMetaData from './organization-metadata';
import OrganizationAbout from './organization-about';

const OrganizationPage = ({ organization }) => (
  <div className="secondary-page all-resources-page">
    <section className="hero projects-hero">
      <div className="hero-container">
        <h1>{organization.display_name}</h1>
        <p>{organization.description}</p>
      </div>
    </section>
    <section className="resources-container">
      <div style={{ paddingTop: '1em' }}>
        <ProjectCardList projects={organization.projects} />
      </div>
    </section>
    <section className="organization-metadata-about-container">
      <OrganizationMetaData organization={organization} />
      <OrganizationAbout className="organization-about" organization={organization} />
    </section>
  </div>
);

OrganizationPage.defaultProps = {
  organization: {}
};

OrganizationPage.propTypes = {
  organization: React.PropTypes.shape({
    projects: React.PropTypes.arrayOf(React.PropTypes.object),
    description: React.PropTypes.string,
    display_name: React.PropTypes.string
  }).isRequired
};

export default OrganizationPage;
