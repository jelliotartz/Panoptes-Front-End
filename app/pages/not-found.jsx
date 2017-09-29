import React from 'react';
import Translate from 'react-translate-component';

const NotFoundPage = () =>
  (<div className="content-container">
    <i className="fa fa-frown-o" aria-hidden="true" />{' '}
    <Translate content="notFoundPage.message" />
  </div>);

export default NotFoundPage;

/*
todo: is there something wrong on router line 250?
adding ?env=production on dev/classifier route does not return not found page
*/
