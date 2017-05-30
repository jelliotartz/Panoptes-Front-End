import React from 'react';
import ProjectCardList from '../projects/project-card-list';
import OrganizationMetaData from './organization-metadata';

const OrganizationPage = ({ organization }) => (
  <div className="secondary-page all-resources-page">
    <section className="hero projects-hero">
      <div className="hero-container">
        <h1>{organization.display_name}</h1>
        <p>{organization.description}</p>
      </div>
    </section>
    <section className="resources-container">
      <div className="organization-project-list">
        <ProjectCardList projects={organization.projects} />
      </div>
    </section>
    <section className="organization-metadata-about-container">
      <OrganizationMetaData organization={organization} />
      <div className="organization-about">
        <h1>ABOUT {organization.display_name}</h1>
        <div className="organization-about--text">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum eu rutrum quam. Integer
          volutpat ante sed ultrices condimentum. Cras vitae ex cursus, blandit lorem ac, dignissim sem.
          Phasellus ac nunc neque. Integer sem augue, gravida a augue vitae, volutpat imperdiet mauris.
          Curabitur vitae efficitur ante, in aliquet tortor.
          Morbi facilisis laoreet eros at finibus. Donec pulvinar porta lobortis. Ut ac tristique orci, a
          bibendum purus. Duis auctor, quam non lobortis aliquet, lorem sapien imperdiet ligula,
          scelerisque pharetra erat elit at nunc. Ut tincidunt velit eget enim luctus blandit. Vivamus ornare
          sodales sem, at pretium ante placerat a. Aenean nec fermentum arcu. Aliquam maximus quam
          quam, non gravida leo varius eget. Donec hendrerit dui purus, nec lobortis lacus dictum sed
          {organization.introduction}
        </div>
      </div>
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
